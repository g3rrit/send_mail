#!/usr/bin/perl
use MIME::Lite;
use Getopt::Long;
use Pod::Usage;
use File::Basename;
use Net::SMTP;

$cc = "";
$subject = "empty";
$port = 465;
$verbose = 0;

GetOptions(
    "help|?" => \$help,
    "c|smtp=s" => \$smtp,
    "u|user=s" => \$user,
    "p|pw=s"=> \$pw,
    "port=i" => \$port,
    "m|message=s" => \$file,
    "t|to=s" => \$to,
    "f|from=s" => \$from,
    "cc=s" => \$cc,
    "s|subject=s" => \$subject,
    "i|image=s@" => \@image,
    "a|attach=s@" => \@attach,
    "v|verbose=i" => \$verbose,
) or pod2usage(2);
pod2usage(1) if $help;

sub check {
    if ($_[0] eq "") {
        print "ERROR: Argument $_[1] required\n";
        exit -1;
    }
}

check $smtp, "smtp";
check $user, "user";
check $pw, "pw";
check $file, "message";
check $from, "from";
check $to, "to";
check $to, "to";

$message = do {
    local $/ = undef;

    if (not basename($file) =~ /.*\.html/ ) {
        print "ERROR: Only html messages allowed\n";
        exit -1;
    }

    open my $fh, "<", $file
        or die "could not open $file: $!";
    <$fh>;
};

if (not defined($smtp)) {
    print "ERROR: No smtp server set\n";
    exit -1;
}

if (not defined($user)) {
    print "ERROR: No user set\n";
    exit -1;
}

$msg = MIME::Lite->new(
    From => $from,
    To => $to,
    Cc => $cc,
    Subject => $subject,
    Type => "multipart/related",
);

$msg->attach(
    Type => "text/html",
    Data => $message,
);

foreach (@image) {
    # Use id of image within email: <img src="cid:image.png">

    my $img_path = $_;
    my $img_name = basename($img_path);

    if (not $img_name =~ /.*\.png/ ) {
        print "ERROR: Only .png images allowed\n";
        exit -1;
    }

    $msg->attach(
        Type => "image/png",
        Path => $img_path,
        Id => $img_name,
    );
}

foreach (@attach) {
    my $attach_path = $_;
    my $attach_name = basename($attach_path);

    $msg->attach(
        Path => $attach_path,
        Filename => $attach_name,
        Disposition => "attachment",
    );  
}

$mailer = Net::SMTP->new(
    $smtp,
    Port => $port,
    Host => $smtp,
    Timeout => 30,
    Debug   => $verbose,
    SSL     => 1,
);

$mailer->auth($user, $pw);
$mailer->mail($from);
$mailer->to($to);
$mailer->data;
$mailer->datasend($msg->as_string);
$mailer->dataend;
$mailer->quit;

print "Done\n";

__END__

=head1 NAME

send_mail.pl - Send mail

=head1 SYNOPSIS

send_mail.pl [options]

=head1 OPTIONS

=over 8

=item B<-?|help>

Print a brief help message and exits.

=item B<-m|msg>

Mail message.

=back

=head1 DESCRIPTION

B<This program> will send a e-mail.

=cut
