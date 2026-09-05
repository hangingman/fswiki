unit class FSWiki::Core;

use FSWiki::Storage::Memory;

has %!hooks;
has %!plugins;
has %!installed-plugins;
has %!plugin-instances;
has @!editform-plugins;
has @!admin-menu;
has @!menu;
has %!handlers;
has %!users;
has $!login-info;
has $.storage = FSWiki::Storage::Memory.new;

method get-page(Str:D $page --> Str:D) {
    $!storage.get-page($page)
}

method save-page(Str:D $page, Str:D $source --> Nil) {
    $!storage.save-page($page, $source)
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

method add-user-handler(Str:D $action, &handler where Callable:D) {
    self!add-handler($action, &handler, 'user', {})
}

method add-admin-handler(Str:D $action, &handler where Callable:D) {
    self!add-handler($action, &handler, 'admin', {})
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
    %input ?? %record<HANDLER>(self, %input) !! %record<HANDLER>(self)
}

method handler-permission(Str:D $action) {
    %!handlers{$action}<PERMISSION>
}

method api-info(Str:D $action) {
    %!handlers{$action}<API>
}
