type regexp = {
  js_regex: Js.Re.t;
  js_regex_global: Js.Re.t;
  original_pattern: string;
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
  }

let regexp_case_fold pattern =
  let js_pattern = Runtime.convert_pattern pattern in
  {
    js_regex = Runtime.make_js_regex js_pattern "id";
    js_regex_global = Runtime.make_js_regex js_pattern "gid";
    original_pattern = pattern;
  }

let quote s =
  Runtime.quote_regex s

let regexp_string s =
  let quoted = Runtime.quote_regex s in
  {
    js_regex = Runtime.make_js_regex quoted "d";
    js_regex_global = Runtime.make_js_regex quoted "gd";
    original_pattern = s;
  }

let regexp_string_case_fold s =
  let quoted = Runtime.quote_regex s in
  {
    js_regex = Runtime.make_js_regex quoted "id";
    js_regex_global = Runtime.make_js_regex quoted "gid";
    original_pattern = s;
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
  match Runtime.exec_from re.js_regex s pos with
  | Some (result, offset) ->
      let index = Js.Re.index result in
      if index = 0 then begin
        Runtime.set_match_info result s offset;
        true
      end else begin
        false
      end
  | None ->
      false

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
