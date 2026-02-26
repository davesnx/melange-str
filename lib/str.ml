type regexp = {
  js_regex: Js.Re.t;
  js_regex_global: Js.Re.t;
  original_pattern: string;
  group_count: int;
}

type split_result =
  | Text of string
  | Delim of string

module Runtime = struct
  type match_info = {
    match_start: int;
    match_end: int;
    groups: (int * int) option array;
  }

  let last_match_info : match_info option ref = ref None

  let clear_match_info () = last_match_info := None

  external get_indices : Js.Re.result -> int array Js.Nullable.t array = "indices" [@@mel.get]

  let set_match_info (result : Js.Re.result) (_input : string) (offset : int) : unit =
    let index = Js.Re.index result in
    let captures = Js.Re.captures result in
    let match_text = Js.Nullable.toOption captures.(0) in

    match match_text with
    | None -> clear_match_info ()
    | Some matched ->
        let match_start = offset + index in
        let match_end = match_start + String.length matched in
        let num_groups = Array.length captures - 1 in

        let groups = Array.make (num_groups + 1) None in
        groups.(0) <- Some (match_start, match_end);

        let indices = get_indices result in
        for i = 1 to num_groups do
          match Js.Nullable.toOption captures.(i) with
          | None -> groups.(i) <- None
          | Some _group_text ->
              (match Js.Nullable.toOption indices.(i) with
               | Some pair ->
                   groups.(i) <- Some (offset + pair.(0), offset + pair.(1))
               | None ->
                   groups.(i) <- None)
        done;

        last_match_info := Some {
          match_start;
          match_end;
          groups;
        }

  let set_partial_match_info (group_count : int) (match_start : int) (match_end : int) : unit =
    let groups = Array.make (group_count + 1) None in
    groups.(0) <- Some (match_start, match_end);
    last_match_info := Some {
      match_start;
      match_end;
      groups;
    }

  let count_groups (pattern : string) : int =
    let len = String.length pattern in
    let rec loop i count =
      if i + 1 >= len then count
      else if pattern.[i] = '\\' && pattern.[i + 1] = '(' then
        loop (i + 2) (count + 1)
      else
        loop (i + 1) count
    in
    loop 0 0

  let is_simple_literal (pattern : string) : string option =
    let len = String.length pattern in
    let buf = Buffer.create len in
    let rec loop i =
      if i >= len then Some (Buffer.contents buf)
      else if pattern.[i] = '\\' then
        if i + 1 >= len then None
        else
          match pattern.[i + 1] with
          | '(' | ')' | '|' | '{' | '}' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9'
          | 'b' | 'n' | 'r' | 't' ->
              None
          | c ->
              Buffer.add_char buf c;
              loop (i + 2)
      else
        match pattern.[i] with
        | '.' | '*' | '+' | '?' | '[' | ']' | '^' | '$' | '|' | '(' | ')' | '{' | '}' ->
            None
        | c ->
            Buffer.add_char buf c;
            loop (i + 1)
    in
    loop 0

  let split_simple_alternation (pattern : string) : string list option =
    let len = String.length pattern in
    let parts = ref [] in
    let start = ref 0 in
    let found = ref false in
    let i = ref 0 in
    while !i + 1 < len do
      if pattern.[!i] = '\\' && pattern.[!i + 1] = '|' then begin
        found := true;
        parts := String.sub pattern !start (!i - !start) :: !parts;
        start := !i + 2;
        i := !i + 2
      end else
        i := !i + 1
    done;
    if not !found then
      None
    else begin
      parts := String.sub pattern !start (len - !start) :: !parts;
      Some (List.rev !parts)
    end

  let is_prefix_of (prefix : string) (full : string) : bool =
    let n = String.length prefix in
    let m = String.length full in
    if n > m then false
    else
      let rec loop i =
        if i = n then true
        else if prefix.[i] = full.[i] then loop (i + 1)
        else false
      in
      loop 0

  let prefix_match_literal (pattern : string) (input : string) : bool option =
    let has_wrapping_group (s : string) : bool =
      let len = String.length s in
      if len < 4 || s.[0] <> '\\' || s.[1] <> '(' then
        false
      else begin
        let depth = ref 0 in
        let closed_at_end = ref false in
        let ok = ref true in
        let i = ref 0 in
        while !ok && !i + 1 < len do
          if s.[!i] = '\\' && s.[!i + 1] = '(' then begin
            depth := !depth + 1;
            i := !i + 2
          end else if s.[!i] = '\\' && s.[!i + 1] = ')' then begin
            depth := !depth - 1;
            if !depth < 0 then ok := false
            else if !depth = 0 then
              if !i + 2 = len then closed_at_end := true else ok := false;
            i := !i + 2
          end else
            i := !i + 1
        done;
        !ok && !depth = 0 && !closed_at_end
      end
    in

    let strip_wrapping_group (s : string) : string option =
      if has_wrapping_group s then
        let len = String.length s in
        Some (String.sub s 2 (len - 4))
      else
        None
    in

    let rec branch_literal s =
      match is_simple_literal s with
      | Some literal -> Some literal
      | None ->
          (match strip_wrapping_group s with
           | Some inner -> branch_literal inner
           | None -> None)
    in

    match is_simple_literal pattern with
    | Some literal -> Some (is_prefix_of input literal)
    | None ->
        (match split_simple_alternation pattern with
         | None -> None
         | Some branches ->
              let rec any = function
                | [] -> false
                | branch :: rest ->
                    (match branch_literal branch with
                     | Some literal when is_prefix_of input literal -> true
                     | _ -> any rest)
              in
              Some (any branches))

  let add_char_once (seen : bool array) (chars : char list ref) (c : char) : unit =
    let code = Char.code c in
    if code < 256 && not seen.(code) then begin
      seen.(code) <- true;
      chars := c :: !chars
    end

  let heuristic_chars (pattern : string) (input : string) : char list =
    let seen = Array.make 256 false in
    let chars = ref [] in

    String.iter (fun c ->
      match c with
      | '\\' | '[' | ']' | '^' | '$' | '(' | ')' | '{' | '}' | '|' | '*' | '+' | '?' | '.' -> ()
      | _ ->
          if Char.code c < 128 then add_char_once seen chars c
    ) pattern;

    String.iter (fun c ->
      if Char.code c < 128 then add_char_once seen chars c
    ) input;

    let defaults = [ 'a'; 'b'; 'c'; '0'; '1'; '_'; ' '; '.'; '@'; '-'; '/' ] in
    List.iter (add_char_once seen chars) defaults;

    List.rev !chars

  let matches_from_start (regex : Js.Re.t) (s : string) : bool =
    match Js.Re.exec ~str:s regex with
    | Some result -> Js.Re.index result = 0
    | None -> false

  let has_prefix_extension (regex : Js.Re.t) (pattern : string) (input : string) : bool =
    match prefix_match_literal pattern input with
    | Some exact -> exact
    | None ->
    let max_extra = 8 in
    let max_attempts = 20000 in
    let attempts = ref 0 in
    let chars = heuristic_chars pattern input in

    let rec search depth_limit depth suffix =
      if !attempts >= max_attempts then false
      else begin
        incr attempts;
        let candidate = input ^ suffix in
        if matches_from_start regex candidate then true
        else if depth >= depth_limit then false
        else
          let rec try_chars = function
            | [] -> false
            | c :: rest ->
                let next = suffix ^ String.make 1 c in
                if search depth_limit (depth + 1) next then true else try_chars rest
          in
          try_chars chars
      end
    in

    let rec deepen limit =
      if limit > max_extra || !attempts >= max_attempts then false
      else if search limit 0 "" then true
      else deepen (limit + 1)
    in
    deepen 0

  let convert_pattern (pattern : string) : string =
    let len = String.length pattern in
    let buf = Buffer.create len in

    let rec convert i =
      if i >= len then ()
      else if pattern.[i] = '\\' && i + 1 < len then
        match pattern.[i + 1] with
        | '(' | ')' | '|' ->
            Buffer.add_char buf pattern.[i + 1];
            convert (i + 2)
        | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' ->
            Buffer.add_char buf '\\';
            Buffer.add_char buf pattern.[i + 1];
            convert (i + 2)
        | 'b' | 'n' | 'r' | 't' | '+' | '*' | '?' | '.' | '^' | '$' | '[' | ']' | '{' | '}' | '\\' ->
            Buffer.add_char buf '\\';
            Buffer.add_char buf pattern.[i + 1];
            convert (i + 2)
        | c ->
            Buffer.add_char buf '\\';
            Buffer.add_char buf c;
            convert (i + 2)
      else begin
        (match pattern.[i] with
         | '|' | '(' | ')' | '{' | '}' ->
             Buffer.add_char buf '\\';
             Buffer.add_char buf pattern.[i]
         | c ->
             Buffer.add_char buf c);
        convert (i + 1)
      end
    in
    convert 0;
    Buffer.contents buf

  let convert_replacement (template : string) : string =
    let len = String.length template in
    let buf = Buffer.create len in

    let rec convert i =
      if i >= len then ()
      else if template.[i] = '\\' && i + 1 < len then
        match template.[i + 1] with
        | '0' ->
            Buffer.add_string buf "$&";
            convert (i + 2)
        | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' as c ->
            Buffer.add_char buf '$';
            Buffer.add_char buf c;
            convert (i + 2)
        | '\\' ->
            Buffer.add_char buf '\\';
            convert (i + 2)
        | c ->
            Buffer.add_char buf '\\';
            Buffer.add_char buf c;
            convert (i + 2)
      else begin
        Buffer.add_char buf template.[i];
        convert (i + 1)
      end
    in
    convert 0;
    Buffer.contents buf

  external make_js_regex : string -> string -> Js.Re.t = "RegExp" [@@mel.new]

  let exec_from (regex : Js.Re.t) (str : string) (start_pos : int) : (Js.Re.result * int) option =
    if start_pos < 0 || start_pos > String.length str then
      None
    else if start_pos = String.length str then
      match Js.Re.exec ~str:"" regex with
      | Some result -> Some (result, start_pos)
      | None -> None
    else
      let substring = String.sub str start_pos (String.length str - start_pos) in
      match Js.Re.exec ~str:substring regex with
      | Some result -> Some (result, start_pos)
      | None -> None

  let exec_all (pattern : string) (str : string) : (Js.Re.result * int) array =
    let regex = make_js_regex pattern "gd" in
    let results = ref [] in
    let continue = ref true in

    while !continue do
      match Js.Re.exec ~str regex with
      | Some result ->
          let index = Js.Re.index result in
          results := (result, index) :: !results;
          let last_index = Js.Re.lastIndex regex in
          if last_index = index then
            Js.Re.setLastIndex regex (index + 1)
      | None ->
          continue := false
    done;

    Array.of_list (List.rev !results)

  let quote_regex (s : string) : string =
    let len = String.length s in
    let buf = Buffer.create (len * 2) in

    for i = 0 to len - 1 do
      match s.[i] with
      | '\\' | '.' | '*' | '+' | '?' | '[' | ']' | '^' | '$' ->
          Buffer.add_char buf '\\';
          Buffer.add_char buf s.[i]
      | c ->
          Buffer.add_char buf c
    done;

    Buffer.contents buf
end

module Internal = struct
  let substring s start end_pos =
    if start < 0 || end_pos > String.length s || start > end_pos then
      invalid_arg "Str: invalid substring bounds"
    else
      String.sub s start (end_pos - start)

  let require_match msg =
    match !Runtime.last_match_info with
    | Some info -> info
    | None -> invalid_arg msg
end

let regexp pattern =
  let js_pattern = Runtime.convert_pattern pattern in
  {
    js_regex = Runtime.make_js_regex js_pattern "d";
    js_regex_global = Runtime.make_js_regex js_pattern "gd";
    original_pattern = pattern;
    group_count = Runtime.count_groups pattern;
  }

let regexp_case_fold pattern =
  let js_pattern = Runtime.convert_pattern pattern in
  {
    js_regex = Runtime.make_js_regex js_pattern "id";
    js_regex_global = Runtime.make_js_regex js_pattern "gid";
    original_pattern = pattern;
    group_count = Runtime.count_groups pattern;
  }

let quote s =
  Runtime.quote_regex s

let regexp_string s =
  let quoted = Runtime.quote_regex s in
  {
    js_regex = Runtime.make_js_regex quoted "d";
    js_regex_global = Runtime.make_js_regex quoted "gd";
    original_pattern = s;
    group_count = 0;
  }

let regexp_string_case_fold s =
  let quoted = Runtime.quote_regex s in
  {
    js_regex = Runtime.make_js_regex quoted "id";
    js_regex_global = Runtime.make_js_regex quoted "gid";
    original_pattern = s;
    group_count = 0;
  }

let string_match re s pos =
  match Runtime.exec_from re.js_regex s pos with
  | Some (result, offset) ->
      let index = Js.Re.index result in
      if index = 0 then begin
        Runtime.set_match_info result s offset;
        true
      end else begin
        Runtime.clear_match_info ();
        false
      end
  | None ->
      Runtime.clear_match_info ();
      false

let search_forward re s start =
  match Runtime.exec_from re.js_regex s start with
  | Some (result, offset) ->
      let index = Js.Re.index result in
      let actual_pos = offset + index in
      Runtime.set_match_info result s offset;
      actual_pos
  | None ->
      Runtime.clear_match_info ();
      raise Not_found

let search_backward re s last =
  let start = min last (String.length s) in
  let rec try_pos pos =
    if pos < 0 then begin
      Runtime.clear_match_info ();
      raise Not_found
    end else
      match Runtime.exec_from re.js_regex s pos with
      | Some (result, offset) when Js.Re.index result = 0 ->
          Runtime.set_match_info result s offset;
          pos
      | _ ->
          try_pos (pos - 1)
  in
  try_pos start

let string_partial_match re s pos =
  if pos < 0 || pos > String.length s then
    invalid_arg "Str.string_partial_match"
  else
  match Runtime.exec_from re.js_regex s pos with
  | Some (result, offset) ->
      let index = Js.Re.index result in
      if index = 0 then begin
        Runtime.set_match_info result s offset;
        true
      end else begin
        Runtime.clear_match_info ();
        false
      end
  | None ->
      let suffix = String.sub s pos (String.length s - pos) in
      if suffix = "" then begin
        Runtime.set_partial_match_info re.group_count pos pos;
        true
      end else if Runtime.has_prefix_extension re.js_regex re.original_pattern suffix then begin
        Runtime.set_partial_match_info re.group_count pos (String.length s);
        true
      end else begin
        Runtime.clear_match_info ();
        false
      end

let matched_string s =
  let info = Internal.require_match "Str.matched_group" in
  Internal.substring s info.match_start info.match_end

let match_beginning () =
  let info = Internal.require_match "Str.group_beginning" in
  info.match_start

let match_end () =
  let info = Internal.require_match "Str.group_end" in
  info.match_end

let matched_group n s =
  let info = Internal.require_match "Str.matched_group" in
  if n < 0 || n >= Array.length info.groups then
    invalid_arg "Str.matched_group"
  else
    match info.groups.(n) with
    | Some (start_pos, end_pos) ->
        Internal.substring s start_pos end_pos
    | None ->
        raise Not_found

let group_beginning n =
  let info = Internal.require_match "Str.group_beginning" in
  if n < 0 || n >= Array.length info.groups then
    invalid_arg "Str.group_beginning"
  else
    match info.groups.(n) with
    | Some (start_pos, _) -> start_pos
    | None -> raise Not_found

let group_end n =
  let info = Internal.require_match "Str.group_end" in
  if n < 0 || n >= Array.length info.groups then
    invalid_arg "Str.group_end"
  else
    match info.groups.(n) with
    | Some (_, end_pos) -> end_pos
    | None -> raise Not_found

external js_string_replace : string -> Js.Re.t -> string -> string = "replace" [@@mel.send]

let global_replace re templ s =
  let js_templ = Runtime.convert_replacement templ in
  Runtime.clear_match_info ();
  js_string_replace s re.js_regex_global js_templ

let replace_first re templ s =
  let js_templ = Runtime.convert_replacement templ in
  Runtime.clear_match_info ();
  js_string_replace s re.js_regex js_templ

let global_substitute re subst s =
  let js_pattern = Runtime.convert_pattern re.original_pattern in
  let all_matches = Runtime.exec_all js_pattern s in

  if Array.length all_matches = 0 then
    s
  else begin
    let buf = Buffer.create (String.length s) in
    let last_pos = ref 0 in

    Array.iter (fun (result, pos) ->
      let index = pos in
      let captures = Js.Re.captures result in
      let matched = Js.Nullable.toOption captures.(0) in

      match matched with
      | Some matched_text ->
          if index > !last_pos then
            Buffer.add_substring buf s !last_pos (index - !last_pos);

          Runtime.set_match_info result s 0;
          let replacement = subst s in
          Buffer.add_string buf replacement;

          last_pos := index + String.length matched_text
      | None -> ()
    ) all_matches;

    if !last_pos < String.length s then
      Buffer.add_substring buf s !last_pos (String.length s - !last_pos);

    Runtime.clear_match_info ();
    Buffer.contents buf
  end

let substitute_first re subst s =
  match Runtime.exec_from re.js_regex s 0 with
  | Some (result, offset) ->
      let index = offset + Js.Re.index result in
      let captures = Js.Re.captures result in
      let matched = Js.Nullable.toOption captures.(0) in

      begin match matched with
      | Some matched_text ->
          let before = String.sub s 0 index in
          let after = String.sub s (index + String.length matched_text)
                                    (String.length s - index - String.length matched_text) in

          Runtime.set_match_info result s offset;
          let replacement = subst s in
          Runtime.clear_match_info ();

          before ^ replacement ^ after
      | None ->
          s
      end
  | None ->
      s

let replace_matched repl s =
  let info = !Runtime.last_match_info in
  let js_repl = Runtime.convert_replacement repl in

  let get_group n =
    match info with
    | None -> failwith "Str.replace: reference to unmatched group"
    | Some i ->
        if n < 0 || n >= Array.length i.groups then
          failwith "Str.replace: reference to unmatched group"
        else
          match i.groups.(n) with
          | Some (start_pos, end_pos) -> Internal.substring s start_pos end_pos
          | None -> failwith "Str.replace: reference to unmatched group"
  in

  let get_whole_match () =
    match info with
    | None -> failwith "Str.replace: reference to unmatched group"
    | Some i -> Internal.substring s i.match_start i.match_end
  in

  let len = String.length js_repl in
  let buf = Buffer.create len in

  let rec process i =
    if i >= len then ()
    else if js_repl.[i] = '$' && i + 1 < len then
      match js_repl.[i + 1] with
      | '&' ->
          Buffer.add_string buf (get_whole_match ());
          process (i + 2)
      | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' as c ->
          let n = Char.code c - Char.code '0' in
          Buffer.add_string buf (get_group n);
          process (i + 2)
      | _ ->
          Buffer.add_char buf '$';
          process (i + 1)
    else begin
      Buffer.add_char buf js_repl.[i];
      process (i + 1)
    end
  in
  process 0;
  Buffer.contents buf

external js_string_split : string -> Js.Re.t -> string array = "split" [@@mel.send]

let split re s =
  Runtime.clear_match_info ();
  let parts = js_string_split s re.js_regex_global in
  let result = Array.to_list parts in
  let strip_first = function
    | "" :: rest -> rest
    | lst -> lst
  in
  let rec strip_last = function
    | [] -> []
    | [""] -> []
    | x :: xs -> x :: strip_last xs
  in
  strip_last (strip_first result)

let bounded_split re s max_splits =
  if max_splits <= 0 then split re s
  else begin
    Runtime.clear_match_info ();
    let js_pattern = Runtime.convert_pattern re.original_pattern in
    let all_matches = Runtime.exec_all js_pattern s in

    let num_splits = min (Array.length all_matches) (max_splits - 1) in
    let result = ref [] in
    let last_pos = ref (String.length s) in

    for i = num_splits - 1 downto 0 do
      let (match_result, pos) = all_matches.(i) in
      let captures = Js.Re.captures match_result in
      match Js.Nullable.toOption captures.(0) with
      | Some matched_text ->
          let match_start = pos in
          let match_end = pos + String.length matched_text in

          if match_end < !last_pos then
            result := String.sub s match_end (!last_pos - match_end) :: !result;

          last_pos := match_start
      | None -> ()
    done;

    if !last_pos > 0 then
      result := String.sub s 0 !last_pos :: !result;

    !result
  end

let split_delim re s =
  if String.length s = 0 then []
  else begin
    Runtime.clear_match_info ();
    let parts = js_string_split s re.js_regex_global in
    Array.to_list parts
  end

let bounded_split_delim re s max_splits =
  if max_splits <= 0 then split_delim re s
  else begin
    Runtime.clear_match_info ();
    let js_pattern = Runtime.convert_pattern re.original_pattern in
    let all_matches = Runtime.exec_all js_pattern s in

    let n_splits = min (Array.length all_matches) (max_splits - 1) in
    let result = ref [] in
    let last_end = ref 0 in

    for i = 0 to n_splits - 1 do
      let (match_result, pos) = all_matches.(i) in
      let captures = Js.Re.captures match_result in
      (match Js.Nullable.toOption captures.(0) with
       | Some matched_text ->
           result := String.sub s !last_end (pos - !last_end) :: !result;
           last_end := pos + String.length matched_text
       | None -> ())
    done;

    result := String.sub s !last_end (String.length s - !last_end) :: !result;
    List.rev !result
  end

let full_split re s =
  Runtime.clear_match_info ();
  let js_pattern = Runtime.convert_pattern re.original_pattern in
  let all_matches = Runtime.exec_all js_pattern s in

  if Array.length all_matches = 0 then
    [Text s]
  else begin
    let result = ref [] in
    let last_pos = ref (String.length s) in

    for i = Array.length all_matches - 1 downto 0 do
      let (match_result, pos) = all_matches.(i) in
      let captures = Js.Re.captures match_result in
      match Js.Nullable.toOption captures.(0) with
      | Some matched_text ->
          let match_start = pos in
          let match_end = pos + String.length matched_text in

          if match_end < !last_pos then
            result := Text (String.sub s match_end (!last_pos - match_end)) :: !result;

          result := Delim matched_text :: !result;

          last_pos := match_start
      | None -> ()
    done;

    if !last_pos > 0 then
      result := Text (String.sub s 0 !last_pos) :: !result;

    !result
  end

let bounded_full_split re s max_splits =
  if max_splits <= 0 then full_split re s
  else begin
    Runtime.clear_match_info ();
    let js_pattern = Runtime.convert_pattern re.original_pattern in
    let all_matches = Runtime.exec_all js_pattern s in

    let n_splits = min (Array.length all_matches) (max_splits - 1) in

    if n_splits = 0 then
      [Text s]
    else begin
      let result = ref [] in
      let last_end = ref 0 in

      for i = 0 to n_splits - 1 do
        let (match_result, pos) = all_matches.(i) in
        let captures = Js.Re.captures match_result in
        (match Js.Nullable.toOption captures.(0) with
         | Some matched_text ->
             if pos > !last_end then
               result := Text (String.sub s !last_end (pos - !last_end)) :: !result;
             result := Delim matched_text :: !result;
             last_end := pos + String.length matched_text
         | None -> ())
      done;

      let remaining = String.sub s !last_end (String.length s - !last_end) in
      if remaining <> "" then
        result := Text remaining :: !result;

      List.rev !result
    end
  end

let string_before s n = String.sub s 0 n

let string_after s n = String.sub s n (String.length s - n)

let first_chars s n = String.sub s 0 n

let last_chars s n = String.sub s (String.length s - n) n
