module RubyBB
	def parse_bbcode(bc)
		def slice(string, si, ei=nil)
			if string.class == Array
				string = string.join
			end
			if ei == nil
				item = string.slice((si % (string.length - 1)), string.length)
			else
				if ei > (string.length - 1)
					ei = string.length - 1
				end
				item = string.slice((si % (string.length - 1)), ((ei % (string.length))))
			end
			return item
		end
		def list_slice(list, si, ei=nil)
			if ei == nil
				item = list.slice((si % (list.length - 1)), list.length)
			else
				item = list.slice((si % (list.length - 1)), ((ei % (list.length))))
			end
			return item
		end
		tokens_found = []
		current_text = ''
		count = -1
		parsing_tag = false
		in_code = false
		code_init = false
		tag_depth = 0
		bc = bc.split("")
		for x in bc
			count += 1
			if parsing_tag
				if x == '['
					tag_depth += 1
				end
				if tag_depth == 0
					current_text = current_text + x
				end
				if x == ']' and tag_depth == 0
					current_text = slice(current_text, 1, -2)
					attr = {}
					for x in current_text.split()
						attr[x.split('=')[0]] = x.split('=')[1]
					end
					tokens_found.push({id:'tag', attributes:attr, value:current_text.split()[0].split('=')[0]})
					parsing_tag = false
					current_text = ''
					next
				elsif x == ']'
					tag_depth -= 1
				end
				if code_init
					in_code = true
					code_init = false
				end
			else 
				n1 = bc[count + 1]
				n2 = bc[count + 2]
				if n1 == nil
					n1 = ''
				end
				if n2 == nil
					n2 = ''
				end
				if x[0] == '[' and (not ((n1 == '[') and (n2 == ']'))) and (not in_code)
					tag_depth = 0
					tokens_found.push({id:'text', value:current_text})
					current_text = '['
					parsing_tag = true
					if slice(bc, count, count + 6) == '[code]'
						code_init = true
					end
					next
				elsif in_code and slice(bc, count, count + 7) == '[/code]'
					tag_depth = 0
					tokens_found.push({id:'text', value:current_text})
					current_text = '['
					parsing_tag = true
					in_code = false
					next                
				else
					current_text = current_text + x
				end
			end
		end
		tokens_found.push({id:'text', value:current_text})
		def compile_tags(tokens, dep=0)
			output = []
			if dep > 0
				name = tokens[0][:value]
			end
			counted = 0
			skip = 0
			bump = ['']
			for x in tokens
				bump.push(x)
			end
			for x in tokens
				counted = counted + 1
				bump = list_slice(bump, 1)
				if skip > 0
					skip = skip - 1
					next
				end
				if dep > 0 and bump.length == tokens.length
					next
				end
				if dep > 0
					if x[:value] == '/' + name
						break
					end
				end
				if x[:id] == 'text'
					output.push(x[:value])
				else
					re = compile_tags(bump, dep + 1)
					skip = re[1]
					output.push({tag:x[:value], value:re[0], param:x[:attributes]})
				end
			end
			if dep > 0
				return [output, counted - 1]
			else
				return output
			end
		end
		return compile_tags(tokens_found)
	end
end