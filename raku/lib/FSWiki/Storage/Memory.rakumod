unit class FSWiki::Storage::Memory;

has %!pages;
has %!physical-modified;
has %!logical-modified;
has %!backups;

method !timestamp(--> Numeric:D) {
    my $modified = DateTime.now.posix;
    my $latest = (%!physical-modified.values, %!logical-modified.values).flat.max // 0;
    $modified = $latest + 0.000001 if $modified <= $latest;
    $modified
}

submethod BUILD(:%pages = {}) {
    %!pages = %pages.Hash;
    my $modified = self!timestamp;
    for %!pages.keys -> $page {
        %!physical-modified{$page} = $modified;
        %!logical-modified{$page} = $modified;
    }
}

method page-exists(Str:D $page --> Bool:D) {
    %!pages{$page}:exists
}

method get-page(Str:D $page --> Str:D) {
    %!pages{$page} // ''
}

method save-page(Str:D $page, Str:D $source --> Nil) {
    %!backups{$page} = %!pages{$page} if %!pages{$page}:exists;
    %!pages{$page} = $source;
    my $modified = self!timestamp;
    %!physical-modified{$page} = $modified;
    %!logical-modified{$page} = $modified;
}

method get-page-list(|capture --> List) {
    my %options = capture.list.elems
        ?? capture.list[0].Hash
        !! capture.hash;
    my $sort = %options<sort> // 'name';
    my $max = %options<max> // 0;
    my @pages = %!pages.keys;
    given $sort {
        when 'name' {
            @pages = @pages.sort;
        }
        when 'last_modified' {
            @pages = @pages.sort(-> $a, $b {
                %!logical-modified{$b} <=> %!logical-modified{$a}
                    || $a cmp $b
            });
        }
        default {
            die "Unknown page-list sort: $sort";
        }
    }
    $max && @pages[^$max] or @pages
}

method get-last-modified(Str:D $page --> Numeric:D) {
    %!physical-modified{$page} // 0
}

method get-last-modified2(Str:D $page --> Numeric:D) {
    %!logical-modified{$page} // self.get-last-modified($page)
}

method backup-type(--> Str:D) {
    'single'
}

method delete-backup-files(Str:D $page --> Nil) {
    %!backups{$page}:delete;
}

method get-backup-list(Str:D $page --> Nil) {
    Nil
}

method get-backup(Str:D $page, Int $gen? --> Str:D) {
    %!backups{$page} // ''
}
