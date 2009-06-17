class Ripper
  class RubyBuilder < Ripper::SexpBuilder
    module Block
      def on_method_add_block(call, block)
        call.block = block
        call
      end

      def on_do_block(params, statements)
        ldelim = pop_token(:@do)
        rdelim = pop_token(:@end)
        separators = pop_tokens(:@semicolon)
        statements.to_block(separators, params, ldelim, rdelim)
      end
      
      def on_brace_block(params, statements)
        ldelim = pop_token(:@lbrace)
        rdelim = pop_token(:@rbrace)
        separators = pop_tokens(:@semicolon)
        statements.to_block(separators, params, ldelim, rdelim)
      end
      
      def on_begin(body)
        body = body.to_named_block unless body.respond_to?(:identifier)
        body.identifier = pop_token(:@begin)
        body.separators += pop_tokens(:@semicolon)
        body.rdelim = pop_token(:@end)
        body
      end
      
      def on_rescue(error_types, error_var, statements, block)
        operator = pop_token(:@op, :value => '=>')
        identifier = pop_token(:@rescue)

        error_types = Ruby::Array.new(error_types)
        errors = Ruby::Assoc.new(error_types, error_var, operator)
        params = Ruby::Params.new(errors)

        Ruby::ChainedBlock.new(identifier, block, statements, params) # TODO extract Ruby::Rescue
      end
      
      def on_ensure(statements)
        identifier = pop_token(:@ensure)
        Ruby::NamedBlock.new(identifier, statements)
      end
      
      def on_block_var(params, something)
        params
      end

      def on_params(params, optional_params, rest_param, something, block_param)
        optional_params.map! do |left, right|
          operator = pop_token(:@op, :value => '=')
          Ruby::Assignment.new(left, right, operator)
        end if optional_params
        
        params = (Array(params) + Array(optional_params) << rest_param << block_param).flatten.compact

        rdelim = pop_token(:@rparen) || pop_token(:@op, :value => '|')
        ldelim = pop_token(:@lparen) || pop_token(:@op, :value => '|')
        separators = pop_tokens(:@comma)

        Ruby::Params.new(params, ldelim, rdelim, separators)
      end

      def on_rest_param(identifier)
        star = pop_token(:@op, :value => '*')
        Ruby::RestParam.new(identifier.token, identifier.position, star)
      end

      def on_paren(params)
        rdelim = pop_token(:@rparen) || pop_token(:@op, :value => '|')
        params.rdelim = rdelim if rdelim
        params
      end
    end
  end
end