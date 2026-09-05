unit class FSWiki::Storage::File;

has IO::Path:D $.dir is required;
has IO::Path $.backup-dir;
has Int:D $.backup = 1;
has %!logical-modified;

method !path(Str:D $page --> IO::Path:D) {
    $!dir.add($page.subst('/', '%2F', :g) ~ '.wiki')
}

method !metadata-dir(--> IO::Path:D) {
    $!dir.add('.fswiki-metadata')
}

method !metadata-path(Str:D $page, Str:D $suffix --> IO::Path:D) {
    self!metadata-dir.add($page.subst('/', '%2F', :g) ~ $suffix)
}

method page-exists(Str:D $page --> Bool:D) {
    self!path($page).f
}

method get-page(Str:D $page --> Str:D) {
    self!path($page).slurp(:bin).decode('UTF-8') if self.page-exists($page)
}

method freeze-page(Str:D $page --> Nil) {
    my $dir = self!metadata-dir;
    $dir.mkdir unless $dir.d;
    self!metadata-path($page, '.freeze').spurt('1\n');
    Nil
}

method un-freeze-page(Str:D $page --> Nil) {
    my $path = self!metadata-path($page, '.freeze');
    $path.unlink if $path.f;
    Nil
}

method is-freeze(Str:D $page --> Bool:D) {
    self!metadata-path($page, '.freeze').f
}

method get-freeze-list(--> List:D) {
    return ().List unless self!metadata-dir.d;
    self!metadata-dir.dir.grep(*.f)
        .grep(*.basename.ends-with('.freeze'))
        .map({ .basename.substr(0, .basename.chars - 7).subst('%2F', '/', :g) })
        .sort.List
}

method set-page-level(Str:D $page, Int:D $level --> Nil) {
    die 'Invalid page level' unless $level ~~ 0..2;
    my $dir = self!metadata-dir;
    if $level == 0 {
        my $path = self!metadata-path($page, '.level');
        $path.unlink if $path.f;
    } else {
        $dir.mkdir unless $dir.d;
        self!metadata-path($page, '.level').spurt($level.Str ~ "\n");
    }
    Nil
}

method get-page-level(Str:D $page --> Int:D) {
    my $path = self!metadata-path($page, '.level');
    $path.f ?? $path.slurp.trim.Int !! 0
}

method save-page(Str:D $page, Str:D $source --> Nil) {
    $!dir.mkdir unless $!dir.d;
    if self.page-exists($page) {
        my $old = self.get-page($page);
        if $old ne $source {
            self!save-backup($page, $old);
        }
    }
    self!path($page).spurt($source, :enc<UTF-8>);
    %!logical-modified{$page} = now.DateTime.posix.Int;
}

method delete-page(Str:D $page --> Nil) {
    my $path = self!path($page);
    $path.unlink if $path.f;
    self.un-freeze-page($page);
    self.set-page-level($page, 0);
    self.delete-backup-files($page);
    %!logical-modified{$page}:delete;
    Nil
}

method get-page-list(Str:D :$sort = 'name', Int:D :$max = 0 --> List:D) {
    my @pages = $!dir.d
        ?? $!dir.dir.grep(*.f).grep(*.extension eq 'wiki').map({ my $name = .basename; $name.substr(0, $name.chars - 5).subst('%2F', '/', :g) }).List
        !! ().List;
    given $sort {
        when 'name' { @pages = @pages.sort(* cmp *) }
        when 'last_modified' {
            @pages = @pages.sort({
                (self.get-last-modified2($^b) <=> self.get-last-modified2($^a)) || ($^a cmp $^b)
            });
        }
        default { die "Unknown page-list sort: $sort" }
    }
    $max > 0 ?? @pages[^($max min @pages.elems)] !! @pages.List
}

method get-last-modified(Str:D $page --> Int:D) {
    self!path($page).modified.DateTime.posix.Int
}

method get-last-modified2(Str:D $page --> Int:D) {
    %!logical-modified{$page} // self.get-last-modified($page)
}

method backup-type(--> Str:D) {
    $!backup == 1 ?? 'single' !! 'all'
}

method !backup-path(Str:D $page, Int:D $generation --> IO::Path:D) {
    my $name = self!path($page).basename;
    $!backup == 1
        ?? self!backup-dir.add($name.subst(/\.wiki$/, '.bak'))
        !! self!backup-dir.add($name.subst(/\.wiki$/, ".{$generation + 1}.bak"));
}

method !backup-dir(--> IO::Path:D) {
    $!backup-dir // $!dir.add('backup')
}

method !save-backup(Str:D $page, Str:D $source --> Nil) {
    my $dir = self!backup-dir;
    $dir.mkdir unless $dir.d;
    if $!backup == 1 {
        self!backup-path($page, 0).spurt($source, :enc<UTF-8>);
    } else {
        my @existing = self.get-backup-list($page) // [];
        self!backup-path($page, @existing.elems).spurt($source, :enc<UTF-8>);
        if $!backup > 1 {
            my @paths = $!backup-dir.dir(:test<file>).grep(*.basename.starts-with(self!path($page).basename.subst(/\.wiki$/, '.'))).sort(*.basename);
            @paths[^(@paths.elems - $!backup)]».unlink if @paths.elems > $!backup;
        }
    }
}

method get-backup-list(Str:D $page --> List:D) {
    return Nil if $!backup == 1 || !self!backup-dir.d;
    self!backup-dir.dir.grep(*.f)
        .grep(*.basename.starts-with(self!path($page).basename.subst(/\.wiki$/, '.')))
        .sort({ $^b.basename cmp $^a.basename })
        .map(*.modified.DateTime.posix.Int).List
}

method get-backup(Str:D $page, Int:D $generation = 0 --> Str:D) {
    my $path = self!backup-path($page, 0);
    if $!backup != 1 {
        my @paths = self!backup-dir.d
            ?? self!backup-dir.dir.grep(*.f)
                .grep(*.basename.starts-with(self!path($page).basename.subst(/\.wiki$/, '.')))
                .sort({ $^b.basename cmp $^a.basename })
            !! [];
        return '' if $generation >= @paths.elems;
        $path = @paths[$generation];
    }
    $path.f ?? $path.slurp(:bin).decode('UTF-8') !! ''
}

method delete-backup-files(Str:D $page --> Nil) {
    return unless self!backup-dir.d;
    self!backup-dir.dir.grep(*.f)
        .grep(*.basename.starts-with(self!path($page).basename.subst(/\.wiki$/, '.')))
        .map({ .unlink });
}
