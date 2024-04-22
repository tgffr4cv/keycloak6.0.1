(*
Module: Sshd_140
  Parses /etc/ssh/sshd_config

  This module is compatible with Augeas 1.4.0, but is not loaded by default.

Author: David Lutterkort lutter@redhat.com
        Dominique Dumont dominique.dumont@hp.com

About: Reference
  sshd_config man page.
  See http://www.openbsd.org/cgi-bin/man.cgi?query=sshd_config&sektion=5

About: License
  This file is licensed under the LGPL v2+.

About: Lens Usage
  Sample usage of this lens in augtool:

    * Get your current setup
      > print /files/etc/ssh/sshd_config
      ...

    * Set X11Forwarding to "no"
      > set /files/etc/ssh/sshd_config/X11Forwarding "no"

  More advanced usage:

    * Set a Match section
      > set /files/etc/ssh/sshd_config/Match[1]/Condition/User "foo"
      > set /files/etc/ssh/sshd_config/Match[1]/Settings/X11Forwarding "yes"

  Saving your file:

      > save


About: CAVEATS

  In sshd_config, Match blocks must be located at the end of the file.
  This means that any new "global" parameters (i.e. outside of a Match
  block) must be written before the first Match block. By default,
  Augeas will write new parameters at the end of the file.

  I.e. if you have a Match section and no ChrootDirectory parameter,
  this command:

     > set /files/etc/ssh/sshd_config/ChrootDirectory "foo"

  will be stored in a new node after the Match section and Augeas will
  refuse to save sshd_config file.

  To create a new parameter as the right place, you must first create
  a new Augeas node before the Match section:

     > ins ChrootDirectory before /files/etc/ssh/sshd_config/Match

  Then, you can set the parameter

     > set /files/etc/ssh/sshd_config/ChrootDirectory "foo"


About: Configuration files
  This lens applies to /etc/ssh/sshd_config

*)

module Sshd_140 =
   let eol = del /[ \t]*\n/ "\n"

   let sep = Util.del_ws_spc

   let indent = del /[ \t]*/ "  "

   let key_re = /[A-Za-z0-9]+/
         - /MACs|Match|AcceptEnv|Subsystem|Ciphers|KexAlgorithms|(Allow|Deny)(Groups|Users)/i

   let comment = Util.comment
   let comment_noindent = Util.comment_noindent
   let empty = Util.empty

   let array_entry (kw:regexp) (sq:string) =
     let value = store /[^ \t\n]+/ in
     [ key kw . [ sep . seq sq . value]* . eol ]

   let other_entry =
     let value = store /[^ \t\n]+([ \t]+[^ \t\n]+)*/ in
     [ key key_re . sep . value . eol ]

   let accept_env = array_entry /AcceptEnv/i "AcceptEnv"

   let allow_groups = array_entry /AllowGroups/i "AllowGroups"
   let allow_users = array_entry /AllowUsers/i "AllowUsers"
   let deny_groups = array_entry /DenyGroups/i "DenyGroups"
   let deny_users = array_entry /DenyUsers/i "DenyUsers"

   let subsystemvalue =
     let value = store (/[^ \t\n](.*[^ \t\n])?/) in
     [ key /[A-Za-z0-9\-]+/ . sep . value . eol ]

   let subsystem =
     [ key /Subsystem/i .  sep .  subsystemvalue ]

   let list (kw:regexp) (sq:string) =
     let value = store /[^, \t\n]+/ in
     [ key kw . sep .
         [ seq sq . value ] .
         ([ seq sq . Util.del_str "," . value])* .
         eol ]

   let macs = list /MACs/i "MACs"

   let ciphers = list /Ciphers/i "Ciphers"

   let kexalgorithms = list /KexAlgorithms/i "KexAlgorithms"

   let entry = accept_env | allow_groups | allow_users
             | deny_groups | subsystem | deny_users
             | macs | ciphers | kexalgorithms
             | other_entry

   let condition_entry =
    let value = store  /[^ \t\n]+/ in
    [ sep . key /[A-Za-z0-9]+/ . sep . value ]

   let match_cond =
     [ label "Condition" . condition_entry+ . eol ]

   let match_entry = indent . (entry | comment_noindent)
                   | empty 

   let match =
     [ key /Match/i . match_cond
        . [ label "Settings" .  match_entry+ ]
     ]

  let lns = (entry | comment | empty)* . match* 

(* Local Variables: *)
(* mode: caml       *)
(* End:             *)