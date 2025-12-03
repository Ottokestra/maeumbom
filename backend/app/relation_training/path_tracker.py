"""
Path tracking utilities for Deep Agent Pipeline
Extracts node paths from result codes (AAAA~BBBB)
"""
from typing import List, Dict, Tuple
from .deep_agent_schemas import NodeData, OptionData, NodePath


def build_tree_structure(
    nodes: List[NodeData],
    options: List[OptionData]
) -> Dict[str, Dict]:
    """
    Build tree structure from nodes and options
    
    Args:
        nodes: List of node data
        options: List of option data
    
    Returns:
        Dict mapping node_id to {children: {option_code: next_node_id}}
    """
    tree = {}
    
    # Initialize tree
    for node in nodes:
        tree[node.id] = {
            "node": node,
            "children": {}
        }
    
    # Build children mapping
    for option in options:
        if option.from_node_id in tree:
            if option.to_node_id:
                tree[option.from_node_id]["children"][option.option_code] = option.to_node_id
            else:
                # This is an ending option (leads to result)
                tree[option.from_node_id]["children"][option.option_code] = None
    
    return tree


def decode_result_code(result_code: str) -> List[str]:
    """
    Decode result code into option codes
    
    Args:
        result_code: Result code (e.g., 'AAAA', 'AAAB', 'BBBB')
    
    Returns:
        List of option codes (e.g., ['A', 'A', 'A', 'A'])
    
    Example:
        >>> decode_result_code('AAAB')
        ['A', 'A', 'A', 'B']
    """
    return list(result_code)


def trace_path(
    result_code: str,
    tree: Dict[str, Dict],
    start_node_id: str = "node_1"
) -> List[str]:
    """
    Trace path from start node to result
    
    Args:
        result_code: Result code (AAAA~BBBB)
        tree: Tree structure from build_tree_structure()
        start_node_id: Starting node ID
    
    Returns:
        List of node IDs in path
    
    Example:
        >>> trace_path('AAAA', tree)
        ['node_1', 'node_2_a', 'node_3_aa', 'node_4_aaa']
    """
    option_codes = decode_result_code(result_code)
    path = [start_node_id]
    current_node_id = start_node_id
    
    for option_code in option_codes:
        if current_node_id not in tree:
            raise ValueError(f"Node {current_node_id} not found in tree")
        
        children = tree[current_node_id]["children"]
        
        if option_code not in children:
            raise ValueError(f"Option {option_code} not found for node {current_node_id}")
        
        next_node_id = children[option_code]
        
        if next_node_id is None:
            # Reached ending
            break
        
        path.append(next_node_id)
        current_node_id = next_node_id
    
    return path


def get_node_texts(node_ids: List[str], nodes: List[NodeData]) -> List[str]:
    """
    Get node texts from node IDs
    
    Args:
        node_ids: List of node IDs
        nodes: List of node data
    
    Returns:
        List of node texts
    """
    node_map = {node.id: node.text for node in nodes}
    return [node_map.get(node_id, "") for node_id in node_ids]


def extract_all_paths(
    result_codes: List[str],
    nodes: List[NodeData],
    options: List[OptionData]
) -> List[NodePath]:
    """
    Extract all paths for result codes
    
    Args:
        result_codes: List of result codes (AAAA~BBBB)
        nodes: List of node data
        options: List of option data
    
    Returns:
        List of NodePath objects
    
    Example:
        >>> paths = extract_all_paths(['AAAA', 'AAAB'], nodes, options)
        >>> paths[0].result_code
        'AAAA'
        >>> paths[0].node_ids
        ['node_1', 'node_2_a', 'node_3_aa', 'node_4_aaa']
    """
    # Build tree structure
    tree = build_tree_structure(nodes, options)
    
    # Extract paths
    paths = []
    for result_code in result_codes:
        try:
            node_ids = trace_path(result_code, tree)
            node_texts = get_node_texts(node_ids, nodes)
            
            path = NodePath(
                result_code=result_code,
                node_ids=node_ids,
                node_texts=node_texts
            )
            paths.append(path)
            
        except Exception as e:
            print(f"[Path Tracker] Error tracing path for {result_code}: {e}")
            # Create empty path as fallback
            paths.append(NodePath(
                result_code=result_code,
                node_ids=[],
                node_texts=[]
            ))
    
    return paths


def summarize_path(node_texts: List[str], max_length: int = 500) -> str:
    """
    Summarize path texts for image generation
    
    Args:
        node_texts: List of node texts
        max_length: Maximum summary length
    
    Returns:
        Summarized text
    
    Example:
        >>> texts = ['남편이 밥투정', '화내며 대응', '더 강하게', '끝까지 싸움']
        >>> summarize_path(texts)
        '남편이 밥투정 → 화내며 대응 → 더 강하게 → 끝까지 싸움'
    """
    # Join with arrow
    summary = " → ".join(node_texts)
    
    # Truncate if too long
    if len(summary) > max_length:
        summary = summary[:max_length-3] + "..."
    
    return summary


def generate_result_code_list() -> List[str]:
    """
    Generate all possible result codes (AAAA~BBBB)
    
    Returns:
        List of 16 result codes
    
    Example:
        >>> codes = generate_result_code_list()
        >>> len(codes)
        16
        >>> codes[0]
        'AAAA'
        >>> codes[-1]
        'BBBB'
    """
    codes = []
    for i in range(16):
        # Convert number to binary (4 bits)
        binary = format(i, '04b')
        # Convert 0->A, 1->B
        code = ''.join('A' if bit == '0' else 'B' for bit in binary)
        codes.append(code)
    return codes

