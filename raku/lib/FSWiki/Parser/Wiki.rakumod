use FSWiki::Parser::Role;

unit class FSWiki::Parser::Wiki does FSWiki::Parser::Role;

sub escape-html(Str:D $text --> Str:D) {
    $text.subst('&', '&amp;', :g)
        .subst('<', '&lt;', :g)
        .subst('>', '&gt;', :g)
        .subst('"', '&quot;', :g)
        .subst("'", '&#39;', :g)
}

method !callback(%context, Str:D $name, |args) {
    my &callback := %context{$name} // return Nil;
    &callback.arity == 0 ?? &callback() !! &callback.arity == 1 ?? &callback(args[0]) !! &callback(|args)
}

method !inline(Str:D $source, %context --> Str:D) {
    my $html = '';
    my $i = 0;
    while $i < $source.chars {
        if $source.substr($i, 1) eq '\\' && $i + 1 < $source.chars {
            $html ~= escape-html($source.substr($i + 1, 1));
            $i += 2;
            next;
        }

        my $matched = False;
        for ["'''", "''", '__', '=='] -> $pair {
            my $open = $pair[0];
            next unless $source.substr($i).starts-with($open);
            my $end = $source.index($open, $i + $open.chars);
            next unless $end.defined && $end > $i + $open.chars;
            my $inner = self!inline($source.substr($i + $open.chars, $end - $i - $open.chars), %context);
            my $tag = $open eq "'''" ?? 'strong' !! $open eq "''" ?? 'em' !! $open eq '__' ?? 'ins' !! 'del';
            $html ~= "<$tag>" ~ $inner ~ "</$tag>";
            $i = $end + $open.chars;
            $matched = True;
            last;
        }
        next if $matched;

        if $source.substr($i).starts-with('[[') {
            my $end = $source.index(']]', $i + 2);
            if $end.defined {
                my $body = $source.substr($i + 2, $end - $i - 2);
                my ($label, $page) = $body.split('|', 2);
                $page //= $label;
                $label = $page unless $body.contains('|');
                my $link = self!callback(%context, 'page-link', $page, $label);
                $html ~= $link.defined ?? $link !! '<a href="?page=' ~ escape-html($page) ~ '" class="wikipage">' ~ escape-html($label) ~ '</a>';
                $i = $end + 2;
                next;
            }
        }

        if $source.substr($i, 1) eq '[' {
            my $end = $source.index(']', $i + 1);
            if $end.defined {
                my $body = $source.substr($i + 1, $end - $i - 1);
                my ($label, $url) = $body.split('|', 2);
                if $url.defined && $url ~~ /^https?\:\/\// {
                    my $link = self!callback(%context, 'url-link', $url, $label);
                    $html ~= $link.defined ?? $link !! '<a href="' ~ escape-html($url) ~ '">' ~ escape-html($label) ~ '</a>';
                    $i = $end + 1;
                    next;
                }
            }
        }

        if $source.substr($i) ~~ /^ (https?\:\/\/ \S+) / {
            my $url = $0.Str;
            my $suffix = '';
            while $url.chars && $url.substr(*-1, 1) ~~ /<[.,)>]>/ {
                $suffix = $url.substr(*-1, 1) ~ $suffix;
                $url = $url.substr(0, $url.chars - 1);
            }
            my $link = self!callback(%context, 'url-link', $url, $url);
            $html ~= $link.defined ?? $link !! '<a href="' ~ escape-html($url) ~ '">' ~ escape-html($url) ~ '</a>';
            $html ~= escape-html($suffix);
            $i += $url.chars + $suffix.chars;
            next;
        }

        $html ~= escape-html($source.substr($i, 1));
        $i++;
    }
    $html
}

method !table-cells(Str:D $line --> Array) {
    my @cells;
    my $cell = '';
    my $quoted = False;
    my $i = 1;
    while $i < $line.chars {
        my $char = $line.substr($i, 1);
        if $char eq '"' {
            if $quoted && $i + 1 < $line.chars && $line.substr($i + 1, 1) eq '"' {
                $cell ~= '"'; $i += 2; next;
            }
            $quoted = !$quoted; $i++; next;
        }
        if $char eq ',' && !$quoted {
            @cells.push($cell.trim); $cell = ''; $i++; next;
        }
        $cell ~= $char; $i++;
    }
    @cells.push($cell.trim);
    @cells
}

method !lists(@entries, %context --> Str:D) {
    my $html = '';
    my @types;
    my @open-li;
    for @entries -> %entry {
        my $level = %entry<level>;
        my $type = %entry<type>;
        while @types.elems > $level {
            $html ~= '</li></' ~ @types.pop ~ '>';
            @open-li.pop;
        }
        while @types.elems < $level {
            my $nested = $type;
            $html ~= "<$nested><li>";
            @types.push($nested); @open-li.push(False);
        }
        if @types[*-1] ne $type {
            $html ~= '</li></' ~ @types.pop ~ '>';
            @open-li.pop;
            $html ~= "<$type><li>";
            @types.push($type); @open-li.push(False);
        }
        if @open-li[*-1] {
            $html ~= '</li><li>';
        }
        $html ~= self!inline(%entry<text>, %context);
        @open-li[*-1] = True;
    }
    while @types {
        $html ~= '</li></' ~ @types.pop ~ '>';
    }
    $html
}

method render(Str:D $source, %context --> Str:D) {
    my @lines = $source.subst("\r", '', :g).split("\n", :skip-empty(False));
    my @out;
    my @paragraph;
    my @list;
    my @quote;
    my @pre;
    my @definitions;
    my @table;
    my $flush = sub {
        if @paragraph { @out.push('<p>' ~ self!inline(@paragraph.join("\n"), %context) ~ '</p>'); @paragraph = (); }
        if @list { @out.push(self!lists(@list, %context)); @list = (); }
        if @quote { @out.push('<blockquote>' ~ @quote.map({ '<p>' ~ self!inline($_, %context) ~ '</p>' }).join ~ '</blockquote>'); @quote = (); }
        if @pre { @out.push('<pre>' ~ escape-html(@pre.join("\n")) ~ '</pre>'); @pre = (); }
        if @definitions { @out.push('<dl>' ~ @definitions.map({ '<dt>' ~ self!inline($_[0], %context) ~ '</dt><dd>' ~ self!inline($_[1], %context) ~ '</dd>' }).join ~ '</dl>'); @definitions = (); }
        if @table { @out.push('<table>' ~ @table.map({ '<tr>' ~ $_.map({ '<td>' ~ self!inline($_, %context) ~ '</td>' }).join ~ '</tr>' }).join ~ '</table>'); @table = (); }
    };

    for @lines -> $line {
        if $line eq '' { $flush(); next; }
        if $line ~~ /^ (\s+) / { $flush() if @paragraph || @list || @quote || @definitions || @table; @pre.push($line); next; }
        if $line eq '----' { $flush(); @out.push('<hr>'); next; }
        if $line.starts-with('!!!') || $line.starts-with('!!') || $line.starts-with('!') {
            $flush(); my $markers = $line.starts-with('!!!') ?? 3 !! $line.starts-with('!!') ?? 2 !! 1;
            my $level = 4 - $markers;
            @out.push('<h' ~ $level ~ '>' ~ self!inline($line.substr($markers), %context) ~ '</h' ~ $level ~ '>'); next;
        }
        if $line ~~ /^ (\* ** 1..3) (.*) $/ || $line ~~ /^ (\+ ** 1..3) (.*) $/ {
            $flush() if @paragraph || @quote || @pre || @definitions || @table;
            my $marker = $0.Str; @list.push({ level => $marker.chars, type => $marker.substr(0,1) eq '*' ?? 'ul' !! 'ol', text => $1.Str }); next;
        }
        if $line.starts-with('""') { $flush() unless @quote; @quote.push($line.substr(2)); next; }
        if $line.starts-with(':') && $line.index(':', 1).defined {
            my $colon = $line.index(':', 1);
            $flush() unless @definitions;
            @definitions.push([$line.substr(1, $colon - 1), $line.substr($colon + 1)]);
            next;
        }
        if $line.starts-with(',') { $flush() unless @table; @table.push(self!table-cells($line)); next; }
        $flush() if @list || @quote || @pre || @definitions || @table;
        @paragraph.push($line);
    }
    $flush();
    @out.join("\n")
}
