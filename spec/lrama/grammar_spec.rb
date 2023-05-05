RSpec.describe Lrama::Grammar do
  describe Lrama::Symbol do
    Token = Lrama::Lexer::Token

    describe "#enum_name" do
      describe "symbol is accept_symbol" do
        it "returns 'YYSYMBOL_YYACCEPT'" do
          sym = Lrama::Symbol.new(id: Token.new(type: Token::Ident, s_value: "$accept"))
          sym.accept_symbol = true

          expect(sym.enum_name).to eq("YYSYMBOL_YYACCEPT")
        end
      end

      describe "symbol is eof_symbol" do
        it "returns 'YYSYMBOL_YYEOF'" do
          sym = Lrama::Symbol.new(id: Token.new(type: Token::Ident, s_value: "YYEOF"), alias_name: "\"end of file\"", token_id: 0)
          sym.number = 0
          sym.eof_symbol = true

          expect(sym.enum_name).to eq("YYSYMBOL_YYEOF")
        end
      end

      describe "symbol's token_id is less than 128" do
        it "returns 'YYSYMBOL_number_[alias_name_]'" do
          sym1 = Lrama::Symbol.new(id: Token.new(type: Token::Char, s_value: "'\\\\'"), alias_name: "\"backslash\"", token_id: 92, number: 70, term: true)
          sym2 = Lrama::Symbol.new(id: Token.new(type: Token::Char, s_value: "'.'"), alias_name: nil, token_id: 46, number: 69, term: true)
          sym3 = Lrama::Symbol.new(id: Token.new(type: Token::Char, s_value: "'\\n'"), alias_name: nil, token_id: 10, number: 162, term: true)

          expect(sym1.enum_name).to eq("YYSYMBOL_70_backslash_")
          expect(sym2.enum_name).to eq("YYSYMBOL_69_")
          expect(sym3.enum_name).to eq("YYSYMBOL_162_n_")
        end
      end

      describe "symbol includes $ or @" do
        it "returns 'YYSYMBOL_number_ref" do
          sym1 = Lrama::Symbol.new(id: Token.new(type: Token::Ident, s_value: "$@1"), token_id: -1, number: 165, term: false)
          sym2 = Lrama::Symbol.new(id: Token.new(type: Token::Ident, s_value: "@2"), token_id: -1, number: 166, term: false)

          expect(sym1.enum_name).to eq("YYSYMBOL_165_1")
          expect(sym2.enum_name).to eq("YYSYMBOL_166_2")
        end
      end

      describe "symbol's token_id is greater than 127" do
        it "returns 'YYSYMBOL_number_ref" do
          sym1 = Lrama::Symbol.new(id: Token.new(type: Token::Ident, s_value: "keyword_class"), alias_name: "\"`class'\"", token_id: 258, number: 3, term: true)
          sym2 = Lrama::Symbol.new(id: Token.new(type: Token::Ident, s_value: "top_compstmt"), token_id: 166, number: -1, term: false)

          expect(sym1.enum_name).to eq("YYSYMBOL_keyword_class")
          expect(sym2.enum_name).to eq("YYSYMBOL_top_compstmt")
        end
      end
    end
  end

  describe Lrama::Code do
    describe "#translated_code" do
      let(:y) do
        <<~INPUT
%{
// Prologue
%}

%union {
  int i;
  long l;
}

%type <i> class

%token <i> keyword_class
%token <i> tSTRING
%token <i> keyword_end

%user-defined-stack rpv { long l2; } <l2>

%%

program: class ;

class : keyword_class tSTRING keyword_end
        {
            $$ = 0;
            $1 = 1;
            $rpv_$ = 10;
            $rpv_1 = 11;
            @$ = 20;
            @1 = 21;
        }
      ;

%%
        INPUT
      end
      let(:grammar) do
        Lrama::Parser.new(y).parse
      end
      let(:code) do
        grammar.rules.last.code
      end

      it "translates DSL to C code" do
        expect(code.translated_code).to eq(<<~CODE.chomp)
          {
                      (yyval.i) = 0;
                      (yyvsp[-2].i) = 1;
                      (yyrpvval.l2) = 10;
                      (yyrpvvsp[-2].l2) = 11;
                      (yyloc) = 20;
                      (yylsp[-2]) = 21;
                  }
        CODE
      end
    end
  end
end