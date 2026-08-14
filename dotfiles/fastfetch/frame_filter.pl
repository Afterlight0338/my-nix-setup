#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");

my $min_width = $ARGV[0] || 56;

sub strip_ansi {
  my ($str) = @_;
  $str =~ s/\x1b\[[0-9;?]*[ -\/]*[@-~]//g;
  $str =~ s/\x1b\][^\a]*\a//g;
  $str =~ s/\x1b_[^\x1b]*\x1b\\//g;
  return $str;
}

sub visual_width {
  my ($str) = @_;
  my $clean = strip_ansi($str);
  my $w = 0;
  for my $char (split //, $clean) {
    my $code = ord($char);
    if ($code >= 0xF0000) {
      $w += 2;
    } else {
      $w += 1;
    }
  }
  return $w;
}

my @all_lines = <STDIN>;
chomp(@all_lines);

my $box_start_idx = -1;
for (my $i = 0; $i < @all_lines; $i++) {
  my $clean = strip_ansi($all_lines[$i]);
  if ($clean =~ /╭.*ROXY'S GRIMOIRE.*/) {
    $box_start_idx = $i;
    last;
  }
}

if ($box_start_idx == -1) {
  for my $line (@all_lines) {
    print "$line\n";
  }
  exit 0;
}

my $max_content_w = 0;
for (my $i = $box_start_idx; $i < @all_lines; $i++) {
  my $clean = strip_ansi($all_lines[$i]);
  if ($clean =~ /╭/ || $clean =~ /├/ || $clean =~ /╰/) { next; }
  $clean =~ s/^\s*//;
  my $vw = visual_width($clean);
  if ($vw > $max_content_w) {
    $max_content_w = $vw;
  }
}

my $box_w = $min_width;
if ($max_content_w + 3 > $box_w) {
  $box_w = $max_content_w + 3;
}

# Print lines before box (logo lines)
for (my $i = 0; $i < $box_start_idx; $i++) {
  print "$all_lines[$i]\n";
}

# Process box lines
for (my $i = $box_start_idx; $i < @all_lines; $i++) {
  my $line = $all_lines[$i];
  my $clean = strip_ansi($line);

  my $prefix = "";
  if ($line =~ /^(\s*)/) {
    $prefix = $1;
  }

  if ($clean =~ /╭.*✦ ROXY'S GRIMOIRE ✦.*/) {
    my $title = " ✦ ROXY'S GRIMOIRE ✦ ";
    my $avail = $box_w - length($title) - 2;
    if ($avail < 2) { $avail = 2; }
    my $left_dash = int($avail / 2);
    my $right_dash = $avail - $left_dash;
    my $formatted = $prefix . "\x1b[38;2;198;169;255m╭" . ("─" x $left_dash) . "\x1b[1m" . $title . "\x1b[22m" . ("─" x $right_dash) . "╮\x1b[0m";
    print "$formatted\n";
  }
  elsif ($clean =~ /├─\s*([A-Z\s]+)\s*─*┤?/) {
    my $sec = $1;
    $sec =~ s/\s+$//;
    my $hdr = "├─ " . $sec . " ";
    my $fill = $box_w - length($hdr) - 1;
    if ($fill < 1) { $fill = 1; }
    my $formatted = $prefix . "\x1b[38;2;140;180;255m" . $hdr . ("─" x $fill) . "┤\x1b[0m";
    print "$formatted\n";
  }
  elsif ($clean =~ /╰─*╯?/) {
    my $fill = $box_w - 2;
    if ($fill < 1) { $fill = 1; }
    my $formatted = $prefix . "\x1b[38;2;198;169;255m╰" . ("─" x $fill) . "╯\x1b[0m";
    print "$formatted\n";
  }
  elsif ($clean =~ /^\s*([a-zA-Z0-9_\-\.]+@[a-zA-Z0-9_\-\.]+)\s*$/) {
    my $user_host = $1;
    my $avail = $box_w - length($user_host) - 2;
    if ($avail < 0) { $avail = 0; }
    my $left_sp = int($avail / 2);
    my $right_sp = $avail - $left_sp;
    my $formatted = $prefix . "\x1b[38;2;198;169;255m│\x1b[0m" . (" " x $left_sp) . "\x1b[1;38;2;198;169;255m" . $user_host . "\x1b[0m" . (" " x $right_sp) . "\x1b[38;2;198;169;255m│\x1b[0m";
    print "$formatted\n";
  }
  elsif ($clean =~ /│/) {
    my $clean_content = $clean;
    $clean_content =~ s/^\s*//;
    my $vw = visual_width($clean_content);
    my $pad_len = $box_w - $vw - 1;
    if ($pad_len < 1) { $pad_len = 1; }
    my $pad = " " x $pad_len;
    my $formatted = $line . $pad . "\x1b[38;2;140;180;255m│\x1b[0m";
    print "$formatted\n";
  }
  else {
    print "$line\n";
  }
}
