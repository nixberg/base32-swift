import Foundation
import Subtle

public extension Sequence where Element == UInt8 {
    func base32EncodedBytes() -> [UInt8] {
        var bytes = self.makeIterator()
        
        guard let first = bytes.next() else {
            return []
        }
        
        var characters: [UInt8] = []
        var accumulator = UInt16(first) << 8
        var unsetBits = 8
        
        while unsetBits < 16 {
            characters.append((accumulator >> 11).mappedToCharacter())
            accumulator <<= 5
            unsetBits += 5
            
            if unsetBits >= 8, let byte = bytes.next() {
                unsetBits -= 8
                accumulator |= UInt16(byte) &<< unsetBits
            }
        }
        
        return characters
    }
    
    func base32EncodedString() -> String {
        String(bytes: self.base32EncodedBytes(), encoding: .ascii)!
    }
}

public extension Array where Element == UInt8 {
    init?<Base32Bytes>(base32Encoded base32Bytes: Base32Bytes)
    where Base32Bytes: Sequence, Base32Bytes.Element == UInt8 {
        self = []
        guard self.appendingEncodedBytes(base32Bytes) else {
            return nil
        }
    }
    
    init?<Base32Bytes>(base32Encoded base32Bytes: Base32Bytes)
    where Base32Bytes: Collection, Base32Bytes.Element == UInt8 {
        self = []
        self.reserveCapacity((base32Bytes.count * 5) / 8)
        guard self.appendingEncodedBytes(base32Bytes) else {
            return nil
        }
    }
    
    init?<Base32String>(base32Encoded base32String: Base32String)
    where Base32String: StringProtocol {
        self = []
        self.reserveCapacity((base32String.count * 5) / 8)
        guard self.appendingEncodedBytes(base32String.utf8) else {
            return nil
        }
    }
    
    private mutating func appendingEncodedBytes<Characters>(_ characters: Characters) -> Bool
    where Characters: Sequence, Characters.Element == UInt8 {
        var characterCount = 0
        
        var accumulator: UInt16 = 0
        var unsetBits = 16
        
        for character in characters {
            guard let bits = character.mappedToBits() else {
                return false
            }
            characterCount += 1
            
            unsetBits -= 5
            accumulator |= UInt16(bits) &<< unsetBits
            
            if unsetBits <= 8 {
                self.append(UInt8(truncatingIfNeeded: accumulator >> 8))
                accumulator <<= 8
                unsetBits += 8
            }
        }
        
        guard [0, 2, 4, 5, 7].contains(characterCount % 8), accumulator == 0 else {
            return false
        }
        
        return true
    }
}

fileprivate extension UInt8 {
    func mappedToCharacter() -> UInt8 {
        assert(self & 0b11111 == self)
        
        let isLessThan10: Choice = self < 10
        let isLessThan18: Choice = self < 18
        let isLessThan20: Choice = self < 20
        let isLessThan22: Choice = self < 22
        let isLessThan28: Choice = self < 28
        
        var character: UInt8 = 0
        character.replace(with: self &- 00 &+ 0x30, if:                  isLessThan10)
        character.replace(with: self &- 10 &+ 0x61, if: !isLessThan10 && isLessThan18)
        character.replace(with: self &- 18 &+ 0x6a, if: !isLessThan18 && isLessThan20)
        character.replace(with: self &- 20 &+ 0x6d, if: !isLessThan20 && isLessThan22)
        character.replace(with: self &- 22 &+ 0x70, if: !isLessThan22 && isLessThan28)
        character.replace(with: self &- 28 &+ 0x77, if: !isLessThan28)
        return character
    }
    
    func mappedToBits() -> UInt8? {
        var bits: UInt8 = 0xff
        bits.replace(with: self &- 0x30 &+ 00, if: (0x29 < self) && (self < 0x40)) // 0123456789
        bits.replace(with: self &- 0x61 &+ 10, if: (0x60 < self) && (self < 0x69)) // abcdefgh
        bits.replace(with: self &- 0x6a &+ 18, if: (0x69 < self) && (self < 0x6c)) // jk
        bits.replace(with: self &- 0x6d &+ 20, if: (0x6c < self) && (self < 0x6f)) // mn
        bits.replace(with: self &- 0x70 &+ 22, if: (0x6f < self) && (self < 0x76)) // pqrstu
        bits.replace(with: self &- 0x77 &+ 28, if: (0x76 < self) && (self < 0x7b)) // wxyz
        return Bool(Choice(bits != 0xff)) ? bits : nil
    }
}

fileprivate extension UInt16 {
    @inline(__always)
    func mappedToCharacter() -> UInt8 {
        UInt8(truncatingIfNeeded: self).mappedToCharacter()
    }
}
