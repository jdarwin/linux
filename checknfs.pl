#!/usr/bin/perl
############################################################################
# Script: checknfs.pl
# Purpose: Run this script before rebooting Linux server, to ensure that all NFS mounts in the server are verified to exist in /etc/fstab for reliable reboot.
# Author: Johnny Darwin
# Date: 22/8/2013
# Installation: IBM India, Pool 67
############################################################################

my $nfs_mounts, $nfs_check_fstab, $str, $fstab_mounts;
my $file;
my @found_entries;
my @missing_nfs;
my $array_count=0;	
my $nfs_source, $nfs_mounted_at, $nfs_type;
print "\n";
print " NFS Check, ver. 1.0\n";
print " --------------------\n";
print "\n";

open (my $fh ,"/proc/mounts") or die ("Cannot open /proc/mounts\n");
my $num=0;
my @nfs_array;
while(<$fh>) {
	$num++;
	my $line = $_;
	($nfs_source, $nfs_mounted_at,$nfs_type) = split(/ /, $line);

	if($nfs_type =~ m{\bnfs\b|\bnfs3\b|\bnfs4\b|\bnfs5\b|nfs6\b}) {
		chomp($line);
		#print "$num: $line\n";
		push(@nfs_array, $line);
	}
}
close($fh);

# Verify if any NFS file system is mounted 
my $found_flag = 0;
foreach my $nfs_item (@nfs_array) {
	($nfs_source, $nfs_mounted_at) = split(/ /, $nfs_item);
	$found_flag=1;
}
# NFS mounts found? If yes, then verify if entered in /etc/fstab
# read entire fstab into array
if ($found_flag == 1) 
{
	open (my $fhfstab ,"/etc/fstab") or die ("Cannot open /etc/fstab\n");
	my $num=0;
	my @fstab_array;
	while(<$fhfstab>) {
		$num++;
		my $line = $_;
		chomp($line);
		push(@fstab_array, $line);
	}
	close($fhfstab);
	# Check here
	foreach my $fstab_item (@fstab_array) {
		my ($fstab_source, $fstab_mounted_at) = split(/\s+/, $fstab_item);
		foreach $nfs_item (@nfs_array) {
			my ($nfs_source, $nfs_mounted_at) = split(/\s+/, $nfs_item);
			if($fstab_mounted_at =~ m{$nfs_mounted_at}) {
				# If comment line?
				my $char = substr($fstab_item, 0, 1);
				if($char ne '#')
				{
					push(@found_entries, $fstab_mounted_at);
				}
			}		
		}
	}
}
$array_count=0;
print "|-----------------------------------------------------------------|\n";
print "| Safe to reboot | Total NFS shares mounted | Total in /etc/fstab |\n";
print "|-----------------------------------------------------------------|\n";
my $total_mounted = $#nfs_array;
my $total_fstab = $#found_entries;
$total_mounted++;
$total_fstab++;

if($total_mounted == $total_fstab) { 
	# No missing nfs shares
	print "      YES"; 
}
else 
{
	print "      NO "; 
}
print "                    $total_mounted";
print "                        $total_fstab\n";
print "-------------------------------------------------------------------\n";
$array_count=0;
foreach $nfs_item(@nfs_array) {
	$found_flag=0;
	foreach $fstab_item(@found_entries) {
		($nfs_source, $nfs_mounted_at) = split(/\s+/, $nfs_item);
		if($fstab_item =~ m{$nfs_mounted_at}) {
			$found_flag=1;
		}
		
	}
	if($found_flag == 0) {
		$array_count++;
		print "\n\n---------------------------- A L E R T ----------------------------\n\n";
		print "Missing in /etc/fstab:\n\n$array_count) $nfs_mounted_at\n";
	}
}

if($ARGV[0] eq '-l') 
{
	$array_count=0;
	if($total_mounted > 0) { print "\nList Mounted :\n\n"; }
	foreach $nfs_item(@nfs_array) {
		my ($nfs_source, $nfs_mounted_at) = split(/\s+/, $nfs_item);
		$array_count++;
		print "$array_count. $nfs_item\n";
	}
	if($total_fstab > 0) { print "\nList /etc/fstab:\n\n"; }
	$array_count=0;
	foreach $fstab_item(@found_entries) {
		$array_count++;
		print "$array_count. $fstab_item\n";
	}
}
else { print "\n\nOptions:\n [-l] list mounts. \nExample: checknfs.pl -l\n"; }
exit;
