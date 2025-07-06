# bash-command-finder

A skript (with English and German version), that helps you find
specific commands from your bash terminal.

Inspired by sysarmy.com/bofhle (Wordle, but with commands instead of words) - loving it!

The script output on the terminal looks like this:

```
> Welcome to the Command Finder!
> Help me narrow down the matching commands.
> How many characters does the command have? (Enter a number or press Enter for any length): 5
> Got it, expected length: 5
> Enter known letters separated by commas (example: a,b,c,x): p
> Enter letters to exclude, separated by commas (example: e,z,q), or press Enter for none: 
> Enter letters that must NOT be at certain positions, but must be included (format: r@2,p@1), or press Enter for none: 
> Enter known letters at specific positions (if any):
> Position 1: 
> Position 2: 
> Position 3: 
> Position 4: 
> Position 5: 
> Your input: _ _ _ _ _   | included: p  | excluded:   | must not be at: 
> Confirm input (c) or re-enter (r)? c
> Matching commands:
  - [...]
```
