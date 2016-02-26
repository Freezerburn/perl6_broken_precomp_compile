use lib '.';
use sdl2;
use OpenGL::Raw;


say "playground init SDL";
sdl-init;
say "playground new window";
my $window = Window.new(:x(0), :y(0));

my $going = True;
while $going {
	for sdl-events() {
		if $_.event-name eq "quit" {
			$going = False;
		}
	}

	glClearColor(0e0, 0e0, 1e0, 1e0);
	glClear(COLOR_BUFFER_BIT);
	$window.swap;
}

say "playground destroy window";
$window.destroy;
say "playground SDL quit";
sdl-quit;
