unit class FSWiki::Core;

use FSWiki::Storage::Memory;
use FSWiki::Parser::Wiki;

has %!hooks;
has %!plugins;
has %!installed-plugins;
has %!plugin-instances;
has %!format-plugins;
has @!editform-plugins;
has @!admin-menu;
has @!menu;
has %!handlers;
has %!users;
has %!config;
has %!wiki-children;
has $!title;
has @!head-info;
has $!login-info;
has $.storage = FSWiki::Storage::Memory.new;
has %!processors;
has $!default-processor = 'wiki';
has $!current-edit-format = 'FSWiki';

submethod BUILD(:%config = {}) {
    %!config = %config.Hash;
    %!processors<wiki> = FSWiki::Parser::Wiki.new;
}

method config(Str:D $name, Mu $value?) {
    return %!config{$name} // Nil unless $value.defined;
    %!config{$name} = $value;
}

method farm-is-enable(--> Bool:D) {
    so self.config('farm-enabled')
}

method !valid-wiki-name(Str:D $name --> Bool:D) {
    $name ne '' && $name !~~ /<[\/\\:]>/ && $name !~~ /\.\./
}

method create-wiki(Str:D $name, Str $admin-id?, Str $password? --> Bool:D) {
    die 'Invalid wiki name' unless self!valid-wiki-name($name);
    die "Wiki already exists: $name" if %!wiki-children{$name}:exists;

    my %child = name => $name;
    %child<admin> = { id => $admin-id, password => $password } if $admin-id.defined || $password.defined;
    %!wiki-children{$name} = %child;
    True
}

method remove-wiki(Str:D $name --> Bool:D) {
    return False unless %!wiki-children{$name}:exists;
    %!wiki-children{$name}:delete;
    True
}

method wiki-exists(Str:D $name --> Bool:D) {
    %!wiki-children{$name}:exists
}

method get-wiki-list(--> List:D) {
    %!wiki-children.keys.sort.List
}

method search-child(Str:D $prefix = '' --> List:D) {
    %!wiki-children.keys.grep(*.starts-with($prefix)).sort.List
}

method wiki-child(Str:D $name) {
    %!wiki-children{$name}
}

method set-title(Str:D $title, Bool:D $edit = False --> Nil) {
    $!title = $title;
    Nil
}

method get-title() {
    $!title
}

method !uri-escape(Mu:D $value --> Str:D) {
    my $text = $value.Str;
    my $escaped = '';
    for $text.encode('utf8').list -> $byte {
        my $char = $byte.chr;
        $escaped ~= ($byte == 45 || $byte == 46 || $byte == 95 || $byte == 126
            || $byte >= 48 && $byte <= 57
            || $byte >= 65 && $byte <= 90
            || $byte >= 97 && $byte <= 122)
            ?? $char
            !! '%' ~ $byte.base(16).fmt('%02s').uc;
    }
    $escaped
}

method create-page-url(Str:D $page --> Str:D) {
    self.create-url({ page => $page })
}

method create-url(%params --> Str:D) {
    my $query = %params.keys.sort.map({
        self!uri-escape($_) ~ '=' ~ self!uri-escape(%params{$_})
    }).join('&');
    my $script = self.config('script-name') // '?';
    return $script ~ '?' ~ $query unless $script.ends-with('?') || $script.ends-with('&');
    $script ~ $query
}

method redirect(Str:D $page) {
    self.redirect-url(self.create-page-url($page))
}

method redirect-url(Str:D $url) {
    { status => 302, location => $url }
}

method add-head-info(Str:D $info --> Nil) {
    @!head-info.push($info);
    Nil
}

method get-head-info(--> List:D) {
    @!head-info.List
}

method register-processor(Str:D $name, Mu:D $processor --> FSWiki::Core:D) {
    die 'Processor name is required' if $name eq '';
    die 'Processor must be callable or provide render' unless $processor.^can('render') || $processor ~~ Callable;
    %!processors{$name} = $processor;
    self
}

method select-processor(Str:D $name --> FSWiki::Core:D) {
    die "Unknown processor: $name" unless %!processors{$name}:exists;
    $!default-processor = $name;
    self
}

method current-processor(--> Str:D) {
    $!default-processor
}

method process-wiki(Str:D $source, Str:D :$processor = $!default-processor, *%context --> Str:D) {
    my $renderer := %!processors{$processor} // die "Unknown processor: $processor";
    $renderer.^can('render')
        ?? $renderer.render($source, %context)
        !! ($renderer.arity == 1 ?? $renderer($source) !! $renderer($source, %context))
}

method get-page(Str:D $page --> Str:D) {
    $!storage.get-page($page)
}

method save-page(Str:D $page, Str:D $source --> Nil) {
    $!storage.save-page($page, $source)
}

method delete-page(Str:D $page --> Nil) {
    $!storage.delete-page($page)
}

method page-exists(Str:D $page --> Bool:D) {
    $!storage.page-exists($page)
}

method freeze-page(Str:D $page --> Nil) {
    $!storage.freeze-page($page)
}

method un-freeze-page(Str:D $page --> Nil) {
    $!storage.un-freeze-page($page)
}

method is-freeze(Str:D $page --> Bool:D) {
    $!storage.is-freeze($page)
}

method get-freeze-list(--> List:D) {
    $!storage.get-freeze-list
}

method set-page-level(Str:D $page, Int:D $level --> Nil) {
    $!storage.set-page-level($page, $level)
}

method get-page-level(Str:D $page --> Int:D) {
    $!storage.get-page-level($page)
}

method !current-user-level(--> Int:D) {
    my $login = self.get-login-info;
    !$login.defined ?? 0 !! ($login<type> == 0 ?? 2 !! 1)
}

method can-show(Str:D $page --> Bool:D) {
    self.get-page-level($page) <= self!current-user-level
}

method can-modify-page(Str:D $page --> Bool:D) {
    return False unless self.can-show($page);
    return False if self.is-freeze($page) && self!current-user-level < 2;
    True
}

method add-user(Str:D $id, Str:D $password, Int:D $type --> Nil) {
    %!users{$id} = { pass => $password, type => $type };
    Nil
}

method user-exists(Str:D $id --> Bool:D) {
    %!users{$id}:exists
}

method login-check(Str:D $id, Str:D $password) {
    my %user := %!users{$id} // return Nil;
    return Nil unless %user<pass> eq $password;
    { id => $id, pass => $password, type => %user<type> }
}

method set-login-info(%info --> Nil) {
    $!login-info = %info.Hash;
    Nil
}

method logout(--> Nil) {
    $!login-info = Nil;
    Nil
}

method get-login-info() {
    $!login-info
}

method add-hook(Str:D $name, &callback where Callable:D) {
    %!hooks{$name} //= [];
    %!hooks{$name}.push(&callback);
    self
}

method do-hook(Str:D $name, |args) {
    for (%!hooks{$name} // []).List -> $callback {
        $callback(self, $name, |args);
    }
    self
}

method !add-plugin(Str:D $name, &plugin where Callable:D, Str:D $type, Str:D $format = 'HTML') {
    %!plugins{$name} = {
        CLASS  => &plugin,
        TYPE   => $type,
        FORMAT => $format.uc,
    };
    self
}

method add-inline-plugin(Str:D $name, &plugin where Callable:D, Str:D $format = 'HTML') {
    self!add-plugin($name, &plugin, 'inline', $format)
}

method add-paragraph-plugin(Str:D $name, &plugin where Callable:D, Str:D $format = 'HTML') {
    self!add-plugin($name, &plugin, 'paragraph', $format)
}

method add-block-plugin(Str:D $name, &plugin where Callable:D, Str:D $format = 'HTML') {
    self!add-plugin($name, &plugin, 'block', $format)
}

method plugin-info(Str:D $name) {
    %!plugins{$name}
}

method install-plugin(Str:D $name, &installer where Callable:D --> Bool:D) {
    die 'Invalid plugin name' if $name eq '' || $name !~~ /^<[A..Za..z0..9_\-]>+$/;
    &installer.arity == 0 ?? &installer() !! &installer(self);
    %!installed-plugins{$name} = True;
    True
}

method is-installed(Str:D $name --> Bool:D) {
    %!installed-plugins{$name}:exists
}

method get-plugin-instance(Str:D $name, &factory? where Callable --> Mu) {
    return Nil if $name eq '';
    return %!plugin-instances{$name} if %!plugin-instances{$name}:exists;
    return Nil unless &factory.defined;
    %!plugin-instances{$name} = &factory.arity == 0 ?? &factory() !! &factory(self);
}

method add-format-plugin(Str:D $name, Mu:D $plugin --> FSWiki::Core:D) {
    die 'Format name is required' if $name eq '';
    die 'Format plugin must be callable or an object' unless $plugin.defined;
    %!format-plugins{$name} = $plugin;
    %!plugin-instances{$name}:delete;
    self
}

method get-format-names(--> List:D) {
    (%!format-plugins.keys.List, 'FSWiki').flat.unique.sort.List
}

method !get-format-plugin(Str:D $name --> Mu) {
    return Nil unless %!format-plugins{$name}:exists;
    my $registered := %!format-plugins{$name};
    $registered ~~ Callable
        ?? self.get-plugin-instance($name, $registered)
        !! self.get-plugin-instance($name, -> { $registered })
}

method !convert-format(Str:D $source, Str:D $format, Bool:D $inline, Bool:D $from --> Str:D) {
    return $source if $format eq 'FSWiki';
    my $plugin = self!get-format-plugin($format);
    return $source unless $plugin.defined;

    my @methods = $from
        ?? ($inline ?? <convert-from-fswiki-line convert_from_fswiki_line> !! <convert-from-fswiki convert_from_fswiki>)
        !! ($inline ?? <convert-to-fswiki-line convert_to_fswiki_line> !! <convert-to-fswiki convert_to_fswiki>);
    my $method = @methods.first({ $plugin.^can($_) });
    return $source unless $method.defined;

    my $normalized = $source.subst("\r\n", "\n", :g).subst("\r", "\n", :g);
    $plugin."$method"($normalized)
}

method convert-to-fswiki(Str:D $source, Str:D $format, Bool:D :$inline = False --> Str:D) {
    self!convert-format($source, $format, $inline, False)
}

method convert-from-fswiki(Str:D $source, Str:D $format, Bool:D :$inline = False --> Str:D) {
    self!convert-format($source, $format, $inline, True)
}

method set-edit-format(Str:D $format --> FSWiki::Core:D) {
    $!current-edit-format = $format;
    self
}

method get-edit-format(:$from = False --> Str:D) {
    $!current-edit-format
}

method add-editform-plugin(Mu $plugin, Numeric:D $weight --> Nil) {
    @!editform-plugins.push({ plugin => $plugin, weight => $weight });
    Nil
}

method get-editform-plugins(--> List:D) {
    @!editform-plugins.sort({ $^b<weight> <=> $^a<weight> }).List
}

method add-admin-menu(Str:D $label, Str:D $url, Numeric:D $weight, Str:D $desc --> Nil) {
    @!admin-menu.push({ label => $label, url => $url, weight => $weight, desc => $desc, type => 0 });
    Nil
}

method add-user-menu(Str:D $label, Str:D $url, Numeric:D $weight, Str:D $desc --> Nil) {
    @!admin-menu.push({ label => $label, url => $url, weight => $weight, desc => $desc, type => 1 });
    Nil
}

method get-admin-menu(--> List:D) {
    @!admin-menu.sort({ $^b<weight> <=> $^a<weight> }).List
}

method add-menu(Str:D $name, Str:D $href, Numeric:D $weight, Bool:D $nofollow = False --> Nil) {
    my %entry = name => $name, href => $href, weight => $weight, nofollow => $nofollow;
    my $existing = @!menu.first({ .<name> eq $name });
    $existing ?? ($existing<href> = $href; $existing<weight> = $weight; $existing<nofollow> = $nofollow)
             !! @!menu.push(%entry);
    Nil
}

method get-menu(--> List:D) {
    @!menu.sort({ $^b<weight> <=> $^a<weight> }).List
}

method !add-handler(Str:D $action, &handler where Callable:D, Str:D $permission, %api) {
    %!handlers{$action} = {
        HANDLER    => &handler,
        PERMISSION => $permission,
        API        => %api,
    };
    self
}

method add-handler(Str:D $action, &handler where Callable:D, :%api = {}) {
    self!add-handler($action, &handler, 'public', %api)
}

method add-user-handler(Str:D $action, &handler where Callable:D, :%api = {}) {
    self!add-handler($action, &handler, 'user', %api)
}

method add-admin-handler(Str:D $action, &handler where Callable:D, :%api = {}) {
    self!add-handler($action, &handler, 'admin', %api)
}

method validate-api-input(Str:D $action, %input --> Hash:D) {
    my %record := %!handlers{$action} // die "Unknown action: $action";
    my %schema := %record<API><schema> // {};
    return %input.Hash unless %schema;

    my %normalized;
    for %schema.kv -> $name, %rules {
        my $value = %input{$name};
        die "Invalid API input: $name is required"
            if %rules<required> && !$value.defined;
        next unless $value.defined;

        given %rules<type> {
            when 'Str'  { die "Invalid API input: $name must be a string" unless $value ~~ Str }
            when 'Bool' { die "Invalid API input: $name must be a boolean" unless $value ~~ Bool }
            when 'Int'  { die "Invalid API input: $name must be an integer" unless $value ~~ Int }
            default     { die "Invalid API schema for $action: $name has an unsupported type" }
        }
        die "Invalid API input: page is required" if $name eq 'page' && $value eq '';
        %normalized{$name} = $value;
    }
    %normalized
}

method call-handler(Str:D $action, %input = {}) {
    my %record := %!handlers{$action} // die "Unknown action: $action";
    my $login = self.get-login-info;
    given %record<PERMISSION> {
        when 'user' {
            die "Login required for user action: $action" unless $login.defined;
        }
        when 'admin' {
            die "Admin permission required for action: $action"
                unless $login.defined && $login<type> == 0;
        }
    }
    my %validated = self.validate-api-input($action, %input);
    %validated ?? %record<HANDLER>(self, %validated) !! %record<HANDLER>(self)
}

method handler-permission(Str:D $action) {
    %!handlers{$action}<PERMISSION>
}

method api-info(Str:D $action) {
    %!handlers{$action}<API>
}
