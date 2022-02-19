package interp;

import interp.Expr;




class IfParser {
    var str:String;
    var pos = 0;
    
    var tokens:Array<Token> = [];
    public function new (str:String) {
        this.str = str;
    }
    public function parse() {
        var tokenizer = new IfTokenizer(str);
        tokens = tokenizer.tokenize();
        trace(tokens);
        var expr = expression();
        if (!isAtEnd()) {
            trace(peek());
            throw "Expected only 1 expression";
        }
           
        return expr;
    }
    
    private function expression() {
        return or();
    }
    private function or() {
        var expr:Expr = and();
        if (match(TOr)) {
            var e2 = and();
            expr = EOr(expr, e2);
        }
        return expr;
    }
    private function and() {
        var expr:Expr = equality();
        if (match(TAnd)) {
            var e2 = equality();
            expr = EAnd(expr, e2);
        }
        return expr;
    }
    private function equality() {
        var expr:Expr = unary();
        if (match(TEquals, TNotEquals)) {
            var op = previous();
            var e2 = unary();
            switch (op) {
                case TEquals: 
                    expr = EEquals(expr, e2);
                case TNotEquals: 
                    expr = ENotEquals(expr, e2);
                default:
            }
        } 
        return expr;
    }
    private function unary() {
        if (match(TNot)) {
            // var token = previous();
            var right = unary();
            return ENot(right);
        }

        return primary();
        
    }
    private function primary() {
        if (match(TIdentifier(""), TInt(0), TString(""))) {
            var id = previous();
            switch (id) {
                case TIdentifier(name):
                    return EIdentifier(name);
                case TInt(int):
                    return EInt(int);
                case TString(str2): 
                    return EString(str2);
                default:
            }
        }

        if (match(TLParen)) {
            var expr = expression();
            consume(TRParen, "Expect Right Parenthesis");
            return EGroup(expr);
        }
        throw "failed to find primary()";
        return null;
    }
    private function match(...tokenTypes:Token) {
        for (token  in tokenTypes) {
            if (check(token)) {
                advance();
                return true;
            }
        }
        return false;
    }
    private function consume(type:Token, message:String) {
        if(check(type))
            return advance();
        throw message;
    }
    private function check(tokenType:Token) {
        if (isAtEnd()) 
            return false;
        return peek().getName() == tokenType.getName();
    }
    private function advance() {
        if (!isAtEnd()) {
            pos++;
        }
        return previous();
    }
    private function isAtEnd() {
        return peek() ==  TEof;
    }
    private function peek() {
        return tokens[pos];
    }
    private function peekNext() {
        return tokens[pos + 1];
    }
    private function previous() {
        return tokens[pos - 1];
    }
    
}
