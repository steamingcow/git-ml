type git_object = 
  |Tree_Object of string
  |Blob of string
  |File of string
  |Commit of string
  |Ref of string

module type GitTreeSig = sig 
  type t  
  val value: t -> git_object 
  val empty : t
  val empty_tree_object : t
  val add_child: git_object -> t -> t  
  val add_child_tree: t -> t -> t  
  val add_file: string -> string -> t -> t
  val get_subdirectory_tree: string -> t -> t 
end

module GitTree : GitTreeSig = struct

  type t = Leaf | Node of git_object * t list
  exception EmptyTreeException of string  

  let empty = Leaf

  let empty_tree_object =
    Node (Tree_Object ".", [])
  let equal_node_value n1 n2 = 
    match n1,n2 with
    |Leaf, Leaf -> true
    |Node (o1,_), Node(o2, _) when o1 = o2 -> true
    |_,_ -> false 

  let value = function
    |Leaf -> raise (EmptyTreeException "Empty tree does not have value")
    |Node (o,lst) -> o

  let add_child (obj:git_object) = function
    |Leaf -> Node (obj,[])
    |Node (o,lst) -> Node (o,(Node (obj,[])::lst))

  let rec get_subdirectory_helper (subdirectory:string) = function
    |[] -> Node(Tree_Object (subdirectory),[])
    |h::t when (equal_node_value h (Node (Tree_Object subdirectory, []))) -> h
    |h::t -> (get_subdirectory_helper subdirectory t) 

  let get_subdirectory_tree (subdirectory:string) = function
    |Leaf ->  Node(Tree_Object (subdirectory),[])
    |Node (_,lst) -> get_subdirectory_helper subdirectory lst   

  let add_child_tree (subtree:t) = function
    |Leaf -> subtree
    |Node(o,lst) -> Node(o,subtree::lst)

  let add_file (filename:string) (file_content:string) = function
    |Leaf -> 
      add_child_tree (Node ((File filename), 
                            (Node ((Blob file_content),[])::[]))) 
        empty 
    |Node (o,lst) -> add_child_tree 
                       (Node ((File filename), 
                              (Node ((Blob file_content),[])::[]))) 
                       (Node (o,lst))

end