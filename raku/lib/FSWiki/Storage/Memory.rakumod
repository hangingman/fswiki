unit class FSWiki::Storage::Memory;

has %!pages;

submethod BUILD(:%pages = {}) {
    %!pages = %pages.Hash;
}

method page-exists(Str:D $page --> Bool:D) {
    %!pages{$page}:exists
}

method get-page(Str:D $page --> Str:D) {
    %!pages{$page} // ''
}

method save-page(Str:D $page, Str:D $source --> Nil) {
    %!pages{$page} = $source;
}
