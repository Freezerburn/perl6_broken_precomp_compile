my package EXPORT::DEFAULT {
  our &debug = sub (*@a) {};
  our &info = sub (*@a) {};
  our &warning = sub (*@a) {};
  our &error = sub (*@a) {};
  our &critical = sub (*@a) {};
  if %*ENV<DEBUG> {
    my $debug-level = %*ENV<DEBUG>.Int;
    my &gen-logger = $debug-level > 0 ?? sub ($a) { sub (*@b) { my $m = @b.join(""); say $a ~ " " ~ $m; $m } } !! sub ($) { sub (*@a) {} };
    if $debug-level > 4 { &debug = gen-logger "[DEBUG]" }
    if $debug-level > 3 { &info = gen-logger "[INFO]" }
    if $debug-level > 2 { &warning = gen-logger "[WARNING]" }
    if $debug-level > 1 { &error = gen-logger "[ERROR]" }
    if $debug-level > 0 { &critical = (sub (&l) { sub (*@a) { my $m = &l(@a); die $m; } })(gen-logger("[CRITICAL]")) }
  }
}
