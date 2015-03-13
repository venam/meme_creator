#!/usr/bin/perl
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );
use charnames qw( :full :short );
use File::Basename;


#Stupid local vars
my $LOCATION_PREFIX = "$ENV{HOME}/.telegram/scripts/meme/imgs";
my $LOCATION_OUTPUT = "$ENV{HOME}/.telegram/scripts/meme";
my $HELP = "Usage $0:
-l [--list] \t list all backgrounds for memes
background some_text \t creates the meme and returns its location
";


=head2
list_feels
@params void
@return void
Function used to list (print) all possible feelings/backgrounds
used in the creation of memes
=cut
sub list_feels {
	my @all_feels = glob("$LOCATION_PREFIX/*");
	@all_feels = map { basename($_); }  @all_feels;
	print "Available:\n";
	print "$_\n" for (@all_feels);
}


sub get_width_heigth {
	my ($image_location) = @_;
	my $output = qx#rdjpgcom -v $image_location#;
	$output =~ m/(\d+)w \* (\d+)h/;
	my $width = $1+0;
	my $height = $2+0;
	return ($width, $height);
}


=head2
try_split_text
@params text, width, height, text_size
@returns the new text and the new text_size

this function split the text to try to fit the image
=cut
sub try_split_text {
	my ($text, $width, $height, $text_size) = @_;
	my $lgth = length($text)*($text_size);
	my @words = split / /,$text;

	my $built_string = "";
	if($lgth > $width) {
		my $current_length = 0;
		for my $word (@words){
			$current_length += length($word)+1;
			if ($current_length*($text_size/1.3) > $width) {
				$built_string .= "\n";
				$current_length = 0;
			}
			$built_string .= $word." ";
		}
		$text = $built_string;
	}
	return ($text,$text_size);
}


=head2
create_meme
@params the_feel some_text
@return string
Creates the meme with the text on it
Returns the location of the created meme
=cut
sub create_meme {
	my ($image_feel, $text) = @_;
	return "no such meme feel" unless (-d "$LOCATION_PREFIX/$image_feel");

	my @all_feels = glob("$LOCATION_PREFIX/$image_feel/*.jpg");
	my $random_feel = int(rand(scalar(@all_feels)));

	#TODO splitting
	my $text_size = 32;
	my ($width,$height) = get_width_heigth($all_feels[$random_feel]);

	($text,$text_size) = try_split_text($text, $width, $height, $text_size);

	system(
		"convert",
		$all_feels[$random_feel],
		"-background", "none",
		"-font", "$LOCATION_OUTPUT/impact.ttf",
		"-pointsize", "$text_size",
		"-stroke", "black",
		"-strokewidth", "1",
		"-fill", "white",
		"label: $text",
		"$LOCATION_OUTPUT/meme.png"
	);

	my $padding = 75;
	my $total_lines = $text =~ tr/\n/\n/;
	$padding -= $total_lines*($text_size/2);

	system(
		"composite",
		"-geometry", "+0-$padding",
		"-gravity", "center",
		"$LOCATION_OUTPUT/meme-1.png", "$LOCATION_OUTPUT/meme-0.png",
		"$LOCATION_OUTPUT/meme.png"
	);
	return "$LOCATION_OUTPUT/meme.png";
}



#TODO Use Getopt::Long
if(defined($ARGV[0])) {
	if ($ARGV[0] eq '-l' or $ARGV[0] eq '--list') {
		list_feels;
	}
	elsif(defined($ARGV[1])){
		print create_meme($ARGV[0], $ARGV[1]);
	}
	else {
		print "You need to pass some text too";
		exit(1);
	}
}
else {
	print $HELP;
}
