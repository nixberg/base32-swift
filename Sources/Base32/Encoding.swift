import Subtle

extension Sequence<UInt8> {
    public func base32EncodedBytes() -> Base32EncodedBytesSequence<Self> {
        Base32EncodedBytesSequence(base: self)
    }
}

#if canImport(Foundation)
import Foundation

extension Sequence<UInt8> {
    public func base32EncodedString() -> String {
        String(bytes: self.base32EncodedBytes(), encoding: .ascii)!
    }
}
#endif

public struct Base32EncodedBytesSequence<Base: Sequence<UInt8>>: Sequence {
    public struct Iterator: IteratorProtocol {
        private var iterator: Base.Iterator
        
        private var accumulator: UInt16 = 0
        private var unsetBitsCount = 16
        
        fileprivate init(iterator: Base.Iterator) {
            self.iterator = iterator
        }
        
        public mutating func next() -> UInt8? {
            assert((0...20).contains(unsetBitsCount))
            
            if unsetBitsCount >= 8 {
                if let byte = iterator.next() {
                    assert((8...16).contains(unsetBitsCount))
                    unsetBitsCount -= 8
                    accumulator |= UInt16(byte) &<< unsetBitsCount
                } else if unsetBitsCount >= 16 {
                    return nil
                }
            }
            
            assert((0...15).contains(unsetBitsCount))
            
            defer {
                accumulator <<= 5
                unsetBitsCount += 5
            }
            return UInt8(mappingBitsToCharacter: accumulator >> 11)
        }
    }
    
    fileprivate let base: Base
    
    public func makeIterator() -> Iterator {
        Iterator(iterator: base.makeIterator())
    }
}

extension UInt8 {
    fileprivate init(mappingBitsToCharacter bits: UInt16) {
        assert(bits & 0b0000_0000_0001_1111 == bits)
        
        let bits = Self(truncatingIfNeeded: bits)
        
        let isLessThan10: Choice = bits < 10
        let isLessThan18: Choice = bits < 18
        let isLessThan20: Choice = bits < 20
        let isLessThan22: Choice = bits < 22
        let isLessThan28: Choice = bits < 28
        
        self = 0
        
        self.replace(with: bits &- 00 &+ 0x30, if:                  isLessThan10)
        self.replace(with: bits &- 10 &+ 0x61, if: !isLessThan10 && isLessThan18)
        self.replace(with: bits &- 18 &+ 0x6a, if: !isLessThan18 && isLessThan20)
        self.replace(with: bits &- 20 &+ 0x6d, if: !isLessThan20 && isLessThan22)
        self.replace(with: bits &- 22 &+ 0x70, if: !isLessThan22 && isLessThan28)
        self.replace(with: bits &- 28 &+ 0x77, if: !isLessThan28)
    }
}
