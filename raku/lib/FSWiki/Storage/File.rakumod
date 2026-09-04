unit class FSWiki::Storage::File;

has IO::Path:D $.dir is required;

method !path(Str:D $page --> IO::Path:D) {
    $!dir.add($page.subst('/', '%2F', :g) ~ '.wiki')
}

method page-exists(Str:D $page --> Bool:D) {
    self!path($page).f
}

method get-page(Str:D $page --> Str:D) {
    self!path($page).slurp(:bin).decode('UTF-8') if self.page-exists($page)
}

method save-page(Str:D $page, Str:D $source --> Nil) {
    $!dir.mkdir unless $!dir.d;
    self!path($page).spurt($source, :enc<UTF-8>);
}
