#!/volume/perl/bin/perl -w
#use strict;
#use warnings;
use FileHandle;
use Term::ANSIColor;
use IO::File;
use lib qw(/volume/labtools/lib);
use Getopt::Long;
use Switch;
# input configuration files

my ( $ddl_directory, @f, $help);
GetOptions(
        'r|release=s' =>\$release,
        'd|ddl_file_directory=s'     => \$ddl_directory,
        'f|filename=s' => \@f,
        'h|help' => \$help,
    );

sub _usage()
{print "This command is to be executed with following option parameters \n
Usage : perl ConfigDiff.pl -f <config2> -f <config2> \n
        perl ConfigDiff.pl -r <release version> -f <config1> -f <config2> \n
        perl ConfigDiff.pl -d <ddl_files_directory> -f <config1> -f <config2> \n\n\n";
}
if(!$release)
{$release="";
}
switch($release)
{ case (10.4) {$ddl_directory="/volume/build/junos/11.4/release/11.4R4/src/junos/lib/ddl/input/";}
  case (11.4) {$ddl_directory="/volume/build/junos/11.4/release/11.4R4/src/junos/lib/ddl/input/";}
  case (12.4) {$ddl_directory="/volume/build/junos/11.4/release/11.4R4/src/junos/lib/ddl/input/";}
  else {$ddl_directory="/volume/build/junos/11.4/release/11.4R4/src/junos/lib/ddl/input/";}
}

$ddl_directory="" unless (defined $ddl_directory);

unless(@f){_usage(); exit;}; 
if($help) { _usage(); exit;};

$cfile=$f[0];
$cfile2=$f[1];
if(!$cfile)
{$cfile="";
}
#if(!$cfile2)
#{$cfile2="";
#}
my $option;
my $input1="Compressedfile1";
my $input2="Compressedfile2";
#DataCompression.pl script is called on each Config file to change config to display set and remove other redundant strings
my $conf1=join('','perl DataCompression.pl ',$cfile,' ',$ddl_directory,' > ',$input1);
system($conf1);
if($f[1])
{
my $conf2=join('','perl DataCompression.pl ',$cfile2,' ',$ddl_directory,' > ',$input2);
system($conf2);
}
my $cmd1;my $cmd2;my $cmd;
my @diff1;
my @diff2;
my $resfile="Results.txt";
open (FH,">",$resfile) ;
$cfile=~s/^(.*)\///;
if($f[1])
{
$cfile2=~s/^(.*)\///;
}
# Data from the compressed files
open(Di1, $input1) || die "Can't open $file: $!\n";
@diff1=<Di1>;
if($f[1])
{
open(Di2, $input2) || die "Can't open $file: $!\n";
@diff2=<Di2>;
}
open(si1, $cfile.'set') || die "Can't open $file: $!\n";
@sarray1=<si1>;
if($f[1])
{
open(si2, $cfile2.'set') || die "Can't open $file: $!\n";
@sarray2=<si2>;
}
my $count=0;
my $sn=1;
my $web='web'; 
my $time=localtime;
chomp( my $date = `date +%d_%b_%H_%M` );
$FilePath = 'ConfigDiff_'.$cfile.'_'.$cfile2.'_'.$date.'.html';
# Creating a file handle to print out in html format 
open ($web,">",$FilePath)or die "Couldn't open file! Check permissions : $!";
#Html script to Expand and Collapse the table structure
print $web '<html>
    <head> <link rel="stylesheet" type="text/css" href="sample.css" />
<script>
function clicker(gvar)
{';
 print $web "   var thediv=document.getElementById(gvar);";
 print $web 'if(thediv.style.display == "none"){
     thediv.style.display = "block";
 }else{
     thediv.style.display = "none";
 }
 return false;
}
</script> 
    </head>
    <body><font color="green">
    <center><h2>Configuration file Comparison </h2></center><br>';
# Operation to collect the general file statistics
my $stat1,my $stat2,my $stat3,my $statres;
$cmd="cat ".$f[0]." | wc -l";
$stat1= `$cmd`;
if($f[1])
{
$cmd="cat ".$f[1]." | wc -l";
$stat2= `$cmd`;
}
# Summary Table generator hash. These table entries can be added below to grep more details out of the config files. To add more rows " <Display Term> => ['<grep search string >',<initial count ie 0 >], " can be added in the code. 
my %summary_hash = (
    'BGP neighbor' => [ 'bgp(.*?)neighbor', 0, ],
    interface => [ 'set interface', 0, ],
    LSP => [ 'mpls label-switched-path(.*) to ',0 ],
    L3VPN => ['routing-instances(.*)instance-type(.*)vrf',0],
    VPLS => ['routing-instances(.*)instance-type(.*)vpls',0],
);

#This greps the matching string and counts the occurences
foreach my $iter (keys %summary_hash)
{
    for (my $i=0;$i<scalar(@sarray1);$i++)
{  
    if($sarray1[$i]=~/$summary_hash{$iter}[0]/){$tcount=$summary_hash{$iter}[1];
						$tcount++;				      
						$summary_hash{$iter}[1]=$tcount; undef $tcount;
						push( @{$iter},$sarray1[$i]); 
    }
}
}
# A dynamic Table data is populated from the the hash inputs. The script gives the expand and collapse view of table for Config1  
print $web '<br><H3>Summary Configuartion of ',$cfile,' </H3><br><TABLE BORDER="2">
<B>
<TH> Property </TH>
<TH> Occurrences </TH>';
foreach my $iter (keys %summary_hash)
{
    if ($summary_hash{$iter}[1]) {
	print $web "<script >var gvar = '",$iter,"' </script> <tr><td><input type=button class=button1 value='",$iter,"' onclick='return clicker(";
	print $web '"',$iter,'");';
	print $web "' /></td><td>",$summary_hash{$iter}[1],"</td></tr>";
    }
}
# Table data is called from the corresponding button link on click event for config1 
foreach my $iter (keys %summary_hash)
{
    print $web "</table> ";
    print $web '<div id="',$iter,'" style="display: none;"><table > ';
    foreach (@{$iter}){print $web '<tr><td>',$_,'</td></tr>';}
    print $web '</table></div>  ';
}

print "Line Count of Config_file1 :$cfile: $stat1\n";
print FH "Line Count of Config_file1 :$cfile: $stat1\n";
print $web "<br>Line Count of Configuration File 1: $cfile: $stat1<br>";
if($f[1])
{
foreach my $iter (keys %summary_hash)
{  $summary_hash{$iter}[1]=0;
   undef @{$iter};
}

# A dynamic Table data is populated from the the hash inputs. The script gives the expand and collapse view of table for Config2
foreach my $iter (keys %summary_hash)
{
    for (my $i=0;$i<scalar(@sarray2);$i++)
{  
    if($sarray2[$i]=~/$summary_hash{$iter}[0]/){$tcount=$summary_hash{$iter}[1];
						$tcount++;				      
						$summary_hash{$iter}[1]=$tcount; undef $tcount;
						push( @{$iter},$sarray2[$i]); 
    }
}
}
# Table data is called from the corresponding button link on click event for config2 
print $web '<br><H3>Summary Configuartion of ',$cfile2,' </H3><br><TABLE BORDER="2">
<B>
<TH> Property </TH>
<TH> Occurrences</TH>';
foreach my $iter (keys %summary_hash)
{
    if ($summary_hash{$iter}[1]) {
	print $web "<script >var gvar = '",$iter,"' </script> <tr><td><input type=button class=button1 value='",$iter,"' onclick='return clicker(";
	print $web '"',$iter.' ','");';
	print $web "' /></td><td>",$summary_hash{$iter}[1],"</td></tr>";
    }
}

foreach my $iter (keys %summary_hash)
{
    print $web "</table> ";
    print $web '<div id="',$iter.' ','" style="display: none;"><table > ';
    foreach (@{$iter}){print $web '<tr><td>',$_,'</td></tr>';}
    print $web '</table></div>  ';
}

print "Line Count of Config_file2 $cfile2: $stat2\n";
print FH "Line Count of Config_file2 $cfile2: $stat2\n";
print $web "<br>Line Count of Configuration File 2 : $cfile2: $stat2<br>";
#Table of similar config is populated based on attribute values from digested array of configurations 
print $web '<br><H3>Similar Configuration Properties by Attribute </H3><br>
   <TABLE BORDER="2">
   <B><TH>S.NO.</TH><TH > Configuration property </TH><TH > File 1 <br>config Occurrences </TH><TH > File 2 <br>config Occurrences </TH>';
my @similar,my @simbucket,my @difbucket1,my @difbucket2;

for (my $i=0;$i<scalar(@diff1);$i++)
{if(defined ($diff1[$i]))
{
    my $d1c=$diff1[$i];
    $d1c=~s/^\+//;
    $d1c=~s/#%(.*?)%#//;
	$d1c=~s/\s+$//;
    $diff1[$i]=~s/\s+$//;
    $diff1[$i]=~s/^\s+//;
    for (my $j=0;$j<scalar(@diff2);$j++)
    { if(defined ($diff2[$j]))
      {
	  my $d2c=$diff2[$j];
	  $d2c=~s/^-//;  
	  $d2c=~s/#%(.*?)%#//;
	      $d2c=~s/\s+$//;
	  $diff2[$j]=~s/\s+$//;
	  $diff2[$j]=~s/^\s+//;
	  if((defined ($diff1[$i]))&&(defined ($diff2[$j])))
	  {if ($diff1[$i] eq $diff2[$j])
	   {push (@similar,$diff1[$i]);
	    undef $diff1[$i];
	    undef $diff2[$j];
	    undef $d1c;
	    undef $d2c;
	   }
	   elsif($d1c eq $d2c)
	   {if(($diff1[$i]=~/#%(.*?)%#/)||($diff2[$j]=~/#%(.*?)%#/))
		{ 
		    $diff1[$i]='<'.$diff1[$i];
		    $diff2[$j]='>'.$diff2[$j];
		    my $c1; my $c2;
		    ($c1)=$diff1[$i]=~/#%(.*?)%#/;
			($c2)=$diff2[$j]=~/#%(.*?)%#/;
			push (@simbucket,$diff1[$i],$diff2[$j]);
		    if(!$c1)
		    {$c1=1;}
		    if(!$c2)
		    {$c2=1;}
		    
		    print $web "<tr><td>",$sn++,"</td><td>",$d1c,"</td><td>",$c1,"</td><td>",$c2,"</td></tr>";
		    
		    undef $diff1[$i];
		    undef $diff2[$j];
		    undef $d1c;
		    undef $d2c;
		}
	       }
		}
	   }
	  }
      }
    }

    $sn=1;
#Table of similar config is populated based on attribute and count from digested array of configurations 

    print $web '</table><br><H3>Similar Configuration Properties by Attribute and Count </H3><br><TABLE BORDER="2">
   <B><TH>S.NO.</TH><TH > Configuration property </TH><TH > File 1 <br>config Occurrences </TH><TH > File 2 <br>Config Occurrences </TH>';
    foreach(@similar)
{   if (defined $_ && ($_ ne ''))
    {$_=~s/^\s*//;
     print "$_\n";
     print FH   "$_\n";
     ($nc)=$_=~/#%(.*?)%#/;
	 
	 if(!$nc)
     {$nc=1;}
     
     print $web '<tr><td><font color="blue">';
     print $web '',$sn++,'</font></td><td><font color="blue">',$_,'</font></td><td><font color="blue">',$nc,'</font></td><td><font color="blue">',$nc,"</font></td></tr>";

    }
}
print $web "</TABLE>";
print color 'bold blue';
#output is given in two forms 1) Html file 2) Console Output(with varied color)
foreach(@simbucket)
{   if (defined $_ && ($_ ne ''))
    {$_=~s/^\s*//;
     print "=$_\n";
     print FH  "=$_\n";
    }
}
}
print color 'bold green';
my $cn1=1;
#Standalone properties of each file is populated from Config1
print $web '<br><H3>Unique Configuration Properties of ',$cfile,' </H3><br><TABLE BORDER="2">
<B><TH>S.NO.</TH>
<TH>File 1\'s  Configuration property </TH>
<TH> File 1 <br>config Occurrences </TH>';
foreach(@diff1)
{   if (defined $_ && ($_ ne ''))
    {$_=~s/^\s*//;
     print "<$_\n";
     print FH  "<$_\n";
     ($k1)=$_=~/#%(.*?)%#/;
	 $_=~s/#%(.*?)%#//;
	 if(!$k1)
     {$k1=1;}
     
     print $web "<tr><td>",$cn1++,"</td><td>",$_,"</td><td>",$k1,"</td></tr>";
    }
}
print color 'bold yellow';
print $web '</table><br>';
if($f[1])
{
my $cn2=1;
print $web '<br><H3>Unique Configuration Properties of ',$cfile2,' </H3><br><TABLE BORDER="2">
<B><TH>S.NO.</TH>
<TH>File 2\'s  Configuration property </TH>
<TH> File 1 <br>config Occurrences </TH>';
my $comp1;
my $comp2;
my $id=0;
#Standalone properties of each file is populated from Config2
for(my $v=0;$v<scalar(@diff2);$v++)
{   if (defined $diff2[$v] && ($diff2[$v] ne ''))
    {$diff2[$v]=~s/^\s*//;
     print ">$diff2[$v]\n";
     print FH  ">$diff2[$v]\n";
     ($g2)=$diff2[$v]=~/#%(.*?)%#/;
	 $diff2[$v]=~s/#%(.*?)%#//;
	 if(!$g2)
     {$g2=1;}
     $w=$v+1;
     $diff2[$v]=~s/ +/ /;
     if (defined $diff2[$v])
     {
	 ($comp1)=$diff2[$v]=~/set (.*?) /;
     }
     if (defined $diff2[$w])
     {
	 ($comp2)=$diff2[$w]=~/set (.*?) /;
     }
     print $web "<tr><td>",$cn2++,"</td><td>",$diff2[$v],"</td><td>",$g2,"</td></tr>";

    }
}
print color 'reset';

print $web '</table>';
}
print $web '<script language="JavaScript" type="text/javascript">
</script>
<br></font>
</boby></html>';
$cmd="cat ".$resfile." | wc -l";
$stat3= `$cmd`;
# The file statistics are calculated 
print $web "<br><h3>Compression Statistics </h3><br>Line Count of Configuration File 1: $cfile: $stat1<br>";
if($f[1])
{
print $web "Line Count of Configuration File 2 : $cfile2: $stat2<br>";
}
else
{$stat2=0;
}
print "Line Count of Compressed File : $stat3\n";
print FH "Line Count of Compressed File : $stat3\n";
print $web "Line Count of Compressed File : $stat3<br>";

$statres=($stat3/($stat1+$stat2))*100;
print "Compression Percentage : ",$statres;
print FH "Compression Percentage : ",$statres;
print $web "Compression Percentage : ",$statres,"<br>";

`rm $input1`;
if($f[1])
{
`rm $input2`;
}
close FH;
close $web;

