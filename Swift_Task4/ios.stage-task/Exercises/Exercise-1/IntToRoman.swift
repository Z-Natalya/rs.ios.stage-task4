import Foundation

public extension Int {
    
    var roman: String? {
        
        if (self <= 0 || self > 3999) {
                return nil
        }
    
        
    let decimals = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
        let roman = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"]

        var result = ""
        var number = self

        while number > 0
        {
            for (i, decimal) in decimals.enumerated()
            {
                if number - decimal >= 0 {
                    number -= decimal
                    result += roman[i]
                    break
                }
            }
        }

        return result
    
        
        


}
}
