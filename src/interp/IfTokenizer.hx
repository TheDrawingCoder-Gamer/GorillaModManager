package interp;

using StringTools;

class IfTokenizer {
    var str:String;
    var pos = 0;
    var lastPos = 0;
    var tokens:Array<Token> = [];
    public function new(str:String) {
        this.str = str;
    }

    public function tokenize() {
        while (!isAtEnd()) {
            var c = consume();
            switch (c) {
                case "|" if (match("|")): 
                    tokens.push(TOr);
                case "&" if (match("&")):
                    tokens.push(TAnd);
                case "!":
                    if (match("=")) {
                        tokens.push(TNotEquals);
                    } else {
                        tokens.push(TNot);
                    }
                case "=" if (match("=")):
                    tokens.push(TEquals); 
                case "(": 
                    tokens.push(TLParen);
                case ")": 
                    tokens.push(TRParen);
                case '"': 
                    tokens.push(TString(string()));
                case " " | "\n" | "\r" | "\t":
                    continue;
                case _ if (isAlpha(c)): 
                    tokens.push(TIdentifier(identifier()));
                case _ if (isNumeric(c)): 
                    tokens.push(TInt(integer()));
                default: 
                    throw "Unexpected " + c;
                
            }
            lastPos = pos;
        }
        tokens.push(TEof);
        return tokens;
    }
    private function identifier() {
        while (isNumeric(peek()) || isAlpha(peek())) {
            consume();
        }
        consume();
        return str.substring(lastPos, pos).trim();
    }
    private function string() {
        var contents = "";
        while (!isAtEnd()) {
            switch (consume()) {
                case '"': 
                    break;
                case char: 
                    contents += char;
            }               
        }
        if (isAtEnd()) 
            throw "Unterminated String";
        return contents;
    }
    private function integer() {
        while (isNumeric(peek())) {
            consume();
        }
        consume();
        return Std.parseInt(str.substring(lastPos, pos));
    }
    private function consume() {
        return str.charAt(pos++);
    }
    private function peek() {
        return str.charAt(pos + 1);
    }
    private function isAtEnd() {
        return pos >= str.length;
    }
    private function match(char:String) {
        if (isAtEnd())
            return false;
        if (str.charAt(pos) != char)
            return false;
        pos++;
        return true;
    }
    private static function isAlpha(str:String) {
        return (str >= "a" && str <= "z") || (str >= "A" && str <= "Z") || str == "_";
    } 
    private static function isNumeric(str:String) {
        return (str >= "0" && str <= "9");
    }
}