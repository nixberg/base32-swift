import Subtle

extension RangeReplaceableCollection<UInt8> {
    public init?(base32Encoded characters: some Sequence<UInt8>) {
        self.init()
        
        var characterCount = 0
        
        var accumulator: UInt16 = 0
        var unsetBitsCount = 16
        
        for character in characters {
            guard let bits = UInt8(mappingCharacterToBits: character) else {
                return nil
            }
            characterCount += 1
            
            unsetBitsCount -= 5
            accumulator |= UInt16(bits) &<< unsetBitsCount
            
            if unsetBitsCount <= 8 {
                self.append(UInt8(truncatingIfNeeded: accumulator >> 8))
                accumulator <<= 8
                unsetBitsCount += 8
            }
        }
        
        guard ![1, 3, 6].contains(characterCount % 8), accumulator == 0 else {
            return nil
        }
    }
    
    public init?(base32Encoded characters: some StringProtocol) {
        self.init(base32Encoded: characters.utf8)
    }
}

extension UInt8 {
    fileprivate init?(mappingCharacterToBits character: UInt8) {
        self = 0xff
        
        self.replace(with: character &- 0x30 &+ 00, if: (0x29 < character) && (character < 0x40)) // 0123456789
        self.replace(with: character &- 0x61 &+ 10, if: (0x60 < character) && (character < 0x69)) // abcdefgh
        self.replace(with: character &- 0x6a &+ 18, if: (0x69 < character) && (character < 0x6c)) // jk
        self.replace(with: character &- 0x6d &+ 20, if: (0x6c < character) && (character < 0x6f)) // mn
        self.replace(with: character &- 0x70 &+ 22, if: (0x6f < character) && (character < 0x76)) // pqrstu
        self.replace(with: character &- 0x77 &+ 28, if: (0x76 < character) && (character < 0x7b)) // wxyz
        
        guard Bool(Choice(self != 0xff)) else {
            return nil
        }
    }
}
