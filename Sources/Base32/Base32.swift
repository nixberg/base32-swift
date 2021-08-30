import ConstantTime
import Foundation

public enum DecodingError: Error {
    case dataCorrupted
}

public extension Sequence where Element == UInt8 {
    func base32Encoded() -> String {
        var bytes = self.makeIterator()
        
        guard let first = bytes.next() else {
            return ""
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
        
        return String(bytes: characters, encoding: .ascii)!
    }
}

public extension StringProtocol {
    func appendBase32DecodedBytes<Bytes>(to bytes: inout Bytes) throws
    where Bytes: RangeReplaceableCollection, Bytes.Element == UInt8 {
        if isEmpty {
            return
        }
        
        var accumulator: UInt16 = 0
        var unsetBits = 16
        
        for character in self.utf8 {
            guard let bits = character.mappedToBits() else {
                throw DecodingError.dataCorrupted
            }
            
            unsetBits -= 5
            accumulator |= UInt16(bits) &<< unsetBits
            
            if unsetBits <= 8 {
                bytes.append(UInt8(truncatingIfNeeded: accumulator >> 8));
                accumulator <<= 8
                unsetBits += 8
            }
        }
    }
    
    func base32Decoded() throws -> [UInt8] {
        var bytes: [UInt8] = []
        bytes.reserveCapacity((count * 5) / 8)
        try self.appendBase32DecodedBytes(to: &bytes)
        return bytes
    }
}

fileprivate extension UInt16 {
    @inline(__always)
    func mappedToCharacter() -> UInt8 {
        UInt8(truncatingIfNeeded: self).mappedToCharacter()
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
        character.replace(with: self &- 00 &+ 0x30, if:                  isLessThan10) // 0123456789
        character.replace(with: self &- 10 &+ 0x61, if: !isLessThan10 && isLessThan18) // abcdefgh
        character.replace(with: self &- 18 &+ 0x6a, if: !isLessThan18 && isLessThan20) // jk
        character.replace(with: self &- 20 &+ 0x6d, if: !isLessThan20 && isLessThan22) // mn
        character.replace(with: self &- 22 &+ 0x70, if: !isLessThan22 && isLessThan28) // pqrstu
        character.replace(with: self &- 28 &+ 0x77, if: !isLessThan28)                 // wxyz
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
