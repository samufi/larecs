import re
import sys

def translate_comments(go_code):
    return re.sub(r'//', r'#', go_code)

def translate_variable_declarations(go_code):
    go_code = re.sub(r'var (\w+) (\w+)', r'var \1: \2', go_code)
    go_code = re.sub(r'(\w+) := (.+)', r'var \1 = \2', go_code)
    return go_code

def translate_function_definitions(go_code):
    result = []
    pattern_1 = re.compile(r'func\s+\((\w+)\s+\*(\w+)\)\s+(\w+)\((.*?)\)\s*(\w+)?')
    pattern_2 = re.compile(r'func\s+(\w+)\((.*?)\)\s*(\w+)?')
    
    function_lines = []
    
    for i, line in enumerate(go_code.split('\n')):
        if "func" not in line:
            result.append(line)
            continue
        
        match = list(pattern_1.findall(line))
        
        if match:
            receiver_var, receiver_type, func_name, params, return_type = match[0]
        else:
            match = list(pattern_2.findall(line))
            if not match:
                result.append(line)
                print(line)
                continue
            func_name, params, return_type = match[0]
            receiver_var = ""
        
        arg_string = receiver_var
        if params:
            if receiver_var:
                arg_string += ", "
            arg_string += ", ".join(("{0}: {1}".format(*pair.split()) for pair in params.split(",")))
        
        if return_type:
            return_string = f" -> {return_type}"
        else:
            return_string = ""
            
        line = f"fn {func_name}({arg_string}){return_string}:"
        result.append(line)
        function_lines.append(i)
    
    docstring_start = []
    for i in function_lines:
        for j in range(i-1, -1, -1):
            line = result[j].strip()
            if not line or line[0] != "#":
                break
        docstring_start.append(j + 1)
    
    result_2 = []
    
    last_index = 0
    for start, end in zip(docstring_start, function_lines):
        if start == end:
            continue
        
        result_2.extend(result[last_index:start])
        result_2.append(result[end])
        result_2.append('    """')
        for line in result[start:end]:
            line = line.strip()
            assert line[0] == "#"
            result_2.append("    " + line[1:].strip())
            
        result_2.append('    """')
        last_index = end+1
    
    result_2.extend(result[last_index:-1])
    
    return "\n".join(result_2)

def translate_control_structures(go_code):
    go_code = re.sub(r'if (.+) {', r'if \1:', go_code)
    go_code = re.sub(r'for (\w+), (\w+) := range (.+) {', r'for \1, \2 in enumerate(\3):', go_code)
    go_code = re.sub(r'for (\w+) := range (.+) {', r'for \1 in \2:', go_code)
    go_code = re.sub(r'for (.+); (.+); (.+) {', r'for \1 in range(\2, \3):', go_code)
    return go_code

def remove_go_braces(go_code):
    return go_code.replace('{', '').replace('}', '')

def translate_go_docstring(go_code):
    def replacer(match):
        print(match.group(1), match.group(2), match.group(3))
        comments = match.group(1).strip().split('\n')
        comments = [comment.strip()[2:].strip() for comment in comments]
        docstring = '"""\n' + '\n'.join(comments) + '\n"""'
        func_def = match.group(2)
        indentation = match.group(3)
        return f'{func_def}\n{indentation}{docstring}'
    
    go_code = re.sub(r'((?:\s*//.*\n)+)(\s*func \w+\(.*?\))(\s*)', replacer, go_code)
    return go_code

def translate_go_to_mojo(go_code):
    go_code = translate_comments(go_code)
    go_code = translate_function_definitions(go_code)
    go_code = translate_control_structures(go_code)
    go_code = translate_variable_declarations(go_code)
    go_code = remove_go_braces(go_code)
    return go_code



if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python _translate.py <filename>")
        sys.exit(1)
    
    filename = sys.argv[1]
    
    with open(filename, 'r') as go_file:
        go_code = go_file.read()
    
    mojo_code = translate_go_to_mojo(go_code)
    
    output_filename = filename.replace('.go', '.mojo')
    with open(output_filename, 'w') as mojo_file:
        mojo_file.write(mojo_code)