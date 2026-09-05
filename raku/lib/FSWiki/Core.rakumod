unit class FSWiki::Core;

use FSWiki::Storage::Memory;

has %!hooks;
has %!plugins;
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
