use SDL2::Raw;
use logging;


my %type-to-event = SDL_EventType.enums.map: {$_.value => $_.key};
debug "type to event: ", %type-to-event.perl;


class Window {...}
class Renderer {...}
class GLContext {...}


class Window is rw is export {
  method new(
      Str :$name = "No Name",
      Int :$x = SDL_WINDOWPOS_CENTERED_MASK,
      Int :$y = SDL_WINDOWPOS_CENTERED_MASK,
      Int :$w = 640,
      Int :$h = 480,
      Int :$flags = OPENGL +| ALLOW_HIGHDPI +| RESIZABLE +| SHOWN
  ) {
    debug "new Window - name:$name, x:$x, y:$y, w:$w, h:$h, flags:$flags";
    self.bless(:window(SDL_CreateWindow($name, $x, $y, $w, $h, $flags)), :$x, :$y, :$w, :$h, :$flags);
  }

  method free() {
    debug "free Window";
    self.destroy;
  }

  method destroy() {
    debug "destroy Window";
    $!renderer.destroy;
    $!context.destroy;
    SDL_DestroyWindow($!window);
  }

  submethod BUILD(SDL_Window :$!window, Int :$!x, Int :$!y, Int :$!w, Int :$!h, Int :$!flags) {
    debug "build window";
    if not $!window.defined {
      die "Window not created: " ~ SDL_GetError;
    }

    if $!flags +& OPENGL == OPENGL {
      debug "OPENGL flag used, auto-creating GL context and renderer";
      self.renderer;
      self.gl-context;
      $!context.make-current;
    }
  }

  method renderer(
      :$index = -1,
      :$flags = ACCELERATED +| PRESENTVSYNC
  ) {
    debug "make renderer?";
    if not $!renderer.defined {
      debug "making renderer";
      $!renderer = Renderer.new(self, :$index, :$flags);
    }
    $!renderer;
  }

  method gl-context(
      Int :$major = 3,
      Int :$minor = 2,
      Bool :$core = True
  ) {
    if not $!context.defined {
      debug "making GL context - major:$major, minor:$minor, core:$core";
      SDL_GL_SetAttribute(CONTEXT_MAJOR_VERSION, $major);
      SDL_GL_SetAttribute(CONTEXT_MINOR_VERSION, $minor);
      SDL_GL_SetAttribute(DOUBLEBUFFER, 1);
      SDL_GL_SetAttribute(CONTEXT_PROFILE_MASK, CONTEXT_PROFILE_CORE.value) if $core;
      $!context = GLContext.new(self);
    }
    $!context;
  }

  method swap() {
    if $!context.defined {
      #debug "swapping window";
      SDL_GL_SwapWindow($.window);
    }
  }

  method show() {
    debug "showing window";
    SDL_ShowWindow($!window);
  }

  has SDL_Window $.window;
  has Renderer $!renderer;
  has GLContext $!context;
  has Int $!x;
  has Int $!y;
  has Int $!w;
  has Int $!h;
  has Int $!flags;
}


class Renderer is rw is export {
  method new(
      Window $window,
      :$index = -1,
      :$flags = ACCELERATED +| PRESENTVSYNC
  ) {
    debug "new renderer";
    self.bless(:renderer(SDL_CreateRenderer($window.window, $index, $flags)));
  }

  method free() {
    debug "free renderer";
    self.destroy;
  }

  method destroy() {
    debug "destroy renderer";
    SDL_DestroyRenderer($!renderer);
  }

  submethod BUILD(:$!renderer) {
    debug "build renderer";
    if not $!renderer.defined {
      die "Could not create renderer: " ~ SDL_GetError;
    }
  }

  has SDL_Renderer $!renderer;
}

class GLContext is rw is export {
  method new(Window $window) {
    debug "new GL context";
    self.bless(:window($window.window));
  }

  method BUILD(:$!window) {
    debug "build GL context - ", self.WHICH;
    $!context = SDL_GL_CreateContext($!window);
    if not $!context.defined {
      die "Could not create context: " ~ SDL_GetError;
    }
  }

  method destroy() {
    debug "destroy GL context - ", self.WHICH;
    SDL_GL_DeleteContext($!context);
  }

  method make-current() {
    debug "making GL context current - ", self.WHICH;
    SDL_GL_MakeCurrent($!window, $!context);
  }

  has SDL_GLContext $!context;
  has SDL_Window $!window;
}

# TODO: Think about and lay out how "nice" Perl events will work that will be
# better than the raw events.
class SDLEvent is rw is export {
  method new(SDL_Event $event) {
    self.bless(:$event);
  }

  method BUILD(SDL_Event :$event) {
    debug "event type: ", $event.type;
    debug "event: ", %type-to-event{$event.type.Str};
    $.event-name = %type-to-event{$event.type.Str}.lc;
    debug "build event name: ", $.event-name.perl;
  }

  has $.event-name;
}

class SDLKeyboardEvent is SDL_Event is rw is export {
   method new(SDL_Event $event) {
     self.bless(:$event);
   }

   method BUILD(SDL_Event :$event) {
     my $actual-event = SDL_CastEvent($event);
     $.type = $actual-event.type;
     $.timestamp = $actual-event.timestamp;
     $.window-id = $actual-event.windowID;
     $.state = $actual-event.state;
     $.repeat = $actual-event.repeat;
     $.scancode = $actual-event.sym;
     $.mod = $actual-event.mod;
   }

   has uint32 $.type;
   has uint32 $.timestamp;
   has uint32 $.window-id;
   has uint8  $.state;
   has uint8  $.repeat;
   has int32  $.scancode;
   has int32  $.sym;
   has uint16  $.mod;
}

class SDLMouseMotionEvent is SDL_Event is rw is export {
  method new(SDL_Event $event) {
    self.bless(:$event);
  }

  method BUILD(SDL_Event :$event) {
    my $actual-event = SDL_CastEvent($event);
    $.timestamp = $actual-event.timestamp;
    $.window-id = $actual-event.windowID;
    $.which = $actual-event.which;
    $.state = $actual-event.state;
    $.x = $actual-event.x;
    $.y = $actual-event.y;
    $.xrel = $actual-event.xrel;
    $.yrel = $actual-event.yrel;
  }

  has uint32 $.timestamp;
  has uint32 $.window-id;
  has uint32 $.which;
  has uint32 $.state;
  has int32  $.x;
  has int32  $.y;
  has int32  $.xrel;
  has int32  $.yrel;
}

class SDLQuitEvent is SDL_Event is rw is export {
  method new(SDL_Event $event) {
    self.bless(:$event);
  }

  method BUILD(SDL_Event :$event) {
    my $actual-event = SDL_CastEvent($event);
    $.timestamp = $actual-event.timestamp;
  }

  has int32 $.timestamp;
}


sub sdl-init(
    $flags = TIMER +| AUDIO +| VIDEO +| JOYSTICK +| HAPTIC +| GAMECONTROLLER +| EVENTS
) is export {
  say "SDL init";
  if SDL_Init($flags) {
    die "SDL Init failed: " ~ SDL_GetError();
  }
}

sub sdl-quit() is export {
  debug "SDL quit";
  SDL_Quit();
}

sub sdl-events() is export {
  my @ret = ();
  my $event = SDL_Event.new();
  while SDL_PollEvent($event) > 0 {
    @ret.push($event);
    $event = SDL_Event.new();
  }
  map { SDLEvent.new($_) }, @ret;
}
