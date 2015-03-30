#use strict;
#use warnings;
use IO::File;
use FileHandle;
use List::MoreUtils;
use Term::ANSIColor;
use List::MoreUtils qw(uniq);
use JSON::XS;
use Data::Dumper;
use CGI;

#Directory contents of the Data Definition file (ddl). DDL are used to remove the redundant data from the configuration like the IP addr#esses, interface names and other strings. 
my $directory=$ARGV[1];
unless($directory)
{ $directory="/volume/build/junos/11.4/release/11.4R4/src/junos/lib/ddl/input/";
}
opendir(DIR, $directory) or  print "Given Directory doesn't Exists. Taking the default value\n"; 
$directory="/volume/build/junos/11.4/release/11.4R4/src/junos/lib/ddl/input/";

my $fparse=$directory.'tag.cnf.dd';
my $file = $ARGV[0];
my $parse;my $temp;my @var;
my $count=0;
#Configuration file is read 
sub fileret 
{
    my $fh = FileHandle->new($file,"r");
    if (defined $fh) {
	local $/=undef;    
	$temp=<$fh>;

    }
}
&fileret;
#Configuration contents are striped for comments 
#$temp=~s/((?:\/\*(?:[^*]|(?:\*+[^*\/]))*\*+\/)|(?:\/\/.*))//g;
$temp=~s/## (.*)//g;
$temp=~s/\/* (.*) *\///g;
$temp=~s/"(.*?)"/""/g;
#IPv6 compressed and expanded forms are eliminated from the configuration data based on this regex
$IPv6_re = "\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1/homes/gselvakumar/config/,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*";
my @tmp;
my @matches;
my @array= split('{',$temp);
my $arrsize =scalar(grep {defined $_} @array);
my $arrayitem =1;my $i;my $k;my $count2;my $flag=0;my $bit=0;my $bi=0;my $tree;my @data;my @uniques;
#Configuration data which is in normal hierarchical form is converted into linear(display set) form
for ($i=0; $i<$arrsize; $i++ )
{
    $count = $i;
    $array[$i]=~s/## SECRET-DATA[\s]+/ /gms;    
    #this looks for the leaf node by greping ; 
    if( @matches =( $array[$i]=~/(.*?);(.*?)/gms))
    { 	$count2 = @matches;
        
	for ($k=0; $k<=$count2; $k++)
	{   
	    if(defined $matches[$k])
	    {
		unless($matches[$k] eq "" )
	        {   #braces forms the hierarchy so that is broken down by parsing { and  } 
		    if($bi=()=$matches[$k]=~/(.*?)}/gms)
		    { $bit=$bi+$bit;
		      $count=$count-$bit;
		      
		    }

		    
		    for (my $j=0; $j<$count;$j++)
		    {  	$tree=$tree.$array[$j]; 
		    }
		    $matches[$k]=~s/\s+/ /msg;
		    $matches[$k]=~s/}//msg;
		    
		    $tree=$tree.$matches[$k];
		    $tree=~s/\s+/ /msg;
		    $tree=~s/^ //msg; 
		    #matched data is moved to the data array for manipultaion 
		    push(@data, $tree);
		    $tree="";
		    
		} 
	    }
	}
#particular block nodes are temporarly kept in a array until copied to data array
	$array[$i]=~s/(.*?);(.*?)/ /gms;
	for(my $x=0; $x<$bit; $x++)
	{$array[$i]="}".$array[$i];
	}
	$bit=0; 
	undef @matches;  
	$bi=0; 
    }
#the end of block is rechecked to split the accumulated data from temporay storage
    while(@var=$array[$i]=~/(.*?)}/ms)
    {  $array[$i]=~s/(.*?)}/ /ms;
       $flag+=1;   
       if(defined $array[$i-$flag])
       {  
	   delete $array[$i-$flag];

       }
       else
       {while (!defined $array[$i-$flag])
	{$flag+=1;
	}
	delete $array[$i-$flag];

       }  
    }
    $flag=0; 
}
#the linear form of the Configuration file is generated and stored as <*.cionfigset> 
$file=~s/^(.*)\///;
$setfile=$file."set";
open (setf, ">",$setfile) or die "cant open '$setfile':$!";
#the linear store is accesed to remove the usage specific terms by parsing the Data Definition file 
for (my $lin=0; $lin<scalar(@data);$lin++)
{ 
    $data[$lin].=" ";
    $data[$lin]="set ".$data[$lin];
    print setf "$data[$lin]\n";
    #the apply-group configurations is expanded and applied to get the end configuration items in the list 
    ($apply)=$data[$lin]=~/apply-groups (.*)/;
    $data[$lin]=~s/apply-groups (.*)/apply-groups/;
    #array is used to accomodate whole collection of terms
    if($apply=~/\[/)
    {
	@s=split(" ",$apply);
	push (@applylist,@s);
    }
    else
    {
	push (@applylist,$apply);
    } 
    my $int2=0;
#following regex are used to remove the unnecessary strings 
 if($data[$lin]=~/$IPv6_re[\/\d]{0,}/g)
{
    $data[$lin]=~s/$IPv6_re[\/\d]{0,}/&$1&/g; ##ipv6 regex 
}

if($data[$lin]=~ /(\d+\.\d+\.\d+\.\d+[\/\d]{0,})/g)
{
    $data[$lin]=~s/(\d+\.\d+\.\d+\.\d+[\/\d]{0,})/&$1&/g; ##IPV4 regex
}

if($data[$lin]=~/(description (.*) )/)
{   
    $data[$lin]=~s/(description (.*) )//;  #removing the description terms 
}
if($data[$lin]=~/(inactive(.*) )/)
{   
    $data[$lin]=~s/(inactive(.*) $)//;     #removing the inactive configuration 
}
if($data[$lin]=~/(traceoption (.*) )/)
{   
    $temp1=~s/traceoption//;               
    $data[$lin]=~s/(traceoption (.*) )/traceoption &$temp1&/; #elimiate the traceoptions data 
}
if($data[$lin]=~/(shared-with (.*) )/)
{       $data[$lin]=~s/(shared-with (.*) $)/shared-with ""/;
}
if($data[$lin]=~ /( [A-Za-z]{2}[-]*\d+[\-\/\.\da-zA-Z]{0,})/g)
{   $rr=$1;
    $rr=~s/ +//; 
    $data[$lin]=~s/( [A-Za-z]{2}[-]*\d+[\-\/\.\da-zA-Z]{0,})/ &$rr&/g; ##interface regex
}
elsif($data[$lin]=~ /( [A-Za-z]{2}[-]*\d+[\/\d\A-Za-z]{4}[\.\d]{0,})/g)
{  
    $rr=$1;
    $rr=~s/ +//; 
    $data[$lin]=~s/( [A-Za-z]{2}[-]*\d+[\/\d\A-Za-z]{4}[\.\d]{0,})/ &$rr&/g; ##interface regex
}
elsif($data[$lin]=~ /( [A-Za-z]{2}\d+[\.\d]{0,})/g)
{  $rr=$1;
   $rr=~s/ +//; 
   
   $data[$lin]=~s/( [A-Za-z]{2}\d+[\.\d]{0,})/ &$rr&/g; ##interface regex
}
elsif($data[$lin]=~ /( [A-Za-z\d]{0,}[-]*\d+[\-\/\.\d\A-Za-z]{0,})/g)
{ $rr=$1;
  $rr=~s/ +//; 
  $data[$lin]=~s/( [A-Za-z\d]{0,}[-]*\d+[\-\/\.\d\A-Za-z]{0,})/ &$rr&/g; ##interface regex
}
$data[$lin]=~s/ +/ /g;

if($data[$lin]=~/apply-groups/)
{
    $data[$lin].="apply-groups ".$apply;
    $apply="";
}
}
close setf;
my @files = readdir DIR;
closedir DIR;

#this sub opens the ddl files for the specified location given 
sub filefind 
{
    my $fp = FileHandle->new($fparse,"r");
    if (defined $fp) {
	local $/=undef;    
	$parse=<$fp>;
    }

}
my @gp;my $search;my $groupst;my $groupbf;
my @groupar;my @data1=@data;
my @searchar;my $mark=1;
#now the apply group configuration items are spliced to the configuration items
for (my $li=0; $li<scalar(@data);$li++)
{  

    if(($search)=$data[$li]=~/apply-groups (.*?)\s/)
{
    ($search)=$data[$li]=~/apply-groups (.*)/;
    
    @searchar=split(' ',$search);
    
    foreach (@searchar)
{
    if($_ eq '['||$_ eq ']')
{next;
 
}
#temporary configuration items are added to the data array
for (my $sline=0; $sline<scalar(@data1);$sline++)
{     if(($groupst)=($data1[$sline]=~/^set groups \Q$_\E (.*)/))
      {$groupst="set ".$groupst;
       push (@groupar, $groupst);
      }
}
@groupar = grep { defined } @groupar;
splice @data,$li,$mark,@groupar;
if($_ eq '[')
{$mark=0;
}
if($_ eq ']')
{$mark=1;
} 
undef @groupar;
}
}   
}
#Unique element list is greped  
@uapplylist= uniq(@applylist);
for my $up(@uapplylist)
{ if(defined $up)
  {
      if(($up=~/\[/)||($up=~/\]/))
      { 
      }
      else{
	  for (my $lop;$lop<scalar(@data);$lop++)
          {if($data[$lop]=~/set groups[&^ ]*\Q$up\E[&^ ]*/)
	   { 		  undef $data[$lop];
	   }
	  }
      }
  }
}
my $object;
my $store;
my $type;
@data=sort(@data);
#Identification of  the elegible candidates for removing from the configuration is done here
for (my $lin=0; $lin<scalar(@data);$lin++)
{   my @keyword = split(' ',$data[$lin]);
    my $keysize=@keyword;
    for (my $k=0;$k<$keysize; $k++)
    {

$object=$keyword[$k];
if($keyword[$k] eq 'groups') # this greps the configuration file to parse the module  
{    
    $fparse=$directory.'order.cnf.dd'; # each file is specific to a particular group of config. 
}
elsif($keyword[$k] eq 'system')
{    
    $fparse=$directory.'system.cnf.dd';
}
elsif(($keyword[$k] eq 'routing-instances')||($keyword[$k] eq 'unit'))
{    
    $fparse=$directory.'cos.cnf.dd';
}
elsif(($keyword[$k] eq 'site-identifier')||($keyword[$k] eq 'vrf-target')||($keyword[$k] eq 'route-distinguisher'))
{    
    $fparse=$directory.'l2vpn.cnf.dd';
}
elsif($keyword[$k] eq 'mpls')
{    
    $fparse=$directory.'tag.cnf.dd';
}
elsif($keyword[$k] eq 'bgp')
{    
    $fparse=$directory.'bgp.cnf.dd';
}
elsif($keyword[$k] eq 'vstp')
{    
    $fparse=$directory.'stp.cnf.dd';
}
elsif($keyword[$k] eq 'vlan-id')
{    
    $fparse=$directory.'l2vpn.cnf.dd';
}
elsif($keyword[$k] eq 'members')
{    
    $fparse=$directory.'dcd.cnf.dd';
}
elsif($keyword[$k] eq 'vlans')
{    
    $fparse=$directory.'jived.cnf.dd';
}
elsif($keyword[$k] eq 'firewall')
{    
    $fparse=$directory.'firewall.cnf.dd';
}
elsif($keyword[$k] eq 'policy-options')
{    
    $fparse=$directory.'dyn-profile.cnf.dd';
}
elsif($keyword[$k] eq 'policy-statement')
{    
    $fparse=$directory.'rpd.control.cnf.dd';
}
#type of the attribute is examied and the strings and the numerical data are removed from the config items
&filefind;
my $tp = $parse;
($store)=$tp=~/object \Q$object\E \{(.*?)[\}|\{]/s;
($type)=$store =~/flag setof (.*?);/;
if(!$store)
{   my $tp = $parse;	    
    ($store)=$tp=~/attribute ["]*\Q$object\E["]* \{(.*?)[\}|\{]/s;
    ($type)=$store=~/type setof (.*?)\s/;
    if($type eq '')
    {($type)=$store=~/type (.*?);/;
    }
}
if(!$type)
{
($type)=$store =~/type setof (.*?);/;
}
if(!$type)
{($type)=$store=~/flag (.*);/;
}

$type =~ s/^\s+//;
$type =~ s/\s+$//;
#this replaces the redundant data with identifyable substituion to indicate the item removal 
if((($type eq 'policy-algebra;')||($type=~/enum/)||($type=~/ranged/))&&($data[$lin]=~/$object (.*)/))
{
    my $temp3=$1;
    $temp3=~s/$object//;
    $data[$lin]=~s/$object (.*)/$object \^&$temp3&\^ /;
}
elsif((($type=~/list/)||($type=~/group/)||($type=~/ranged/)||($type=~/vlan-object/)||($type=~/string/)||($type=~/remove-empty/))&&($data[$lin]=~/$object (.*?) /))
{
    my ($temp2)=$data[$lin]=~/$object (.*?) /;
    $temp2=~s/$object //;
    $data[$lin]=~s/$object (.*?) /$object \^&$temp2&\^ /;    
}undef $type;    
$tp=$parse;   
    }
}
sub uniqele (@) {
    my %seen = ();
    grep {not $seen{$_}++ } @_;
}
#Configuration elements are scanned for equivalence 
chomp(@data);
my @tempdata=@data;
my $datasize=@tempdata;
my $inc=1;
for (my $x1=0; $x1<$datasize;$x1++) {
    for(my $x2=0;$x2<$datasize;$x2++) {

	my $eletemp=$tempdata[$x1];
	$eletemp=~s/&(.*?)&//g;    
	$eletemp=~s/\^(.*?)\^//g; 
	
	my $unitemp=$tempdata[$x2];
	$unitemp=~s/&(.*?)&//g;
	$unitemp=~s/\^(.*?)\^//g; 
	
	$eletemp =~s/\s+$//;
	$unitemp=~s/\s+$//;
	if($x1 == $x2)
	{
	}
	elsif($eletemp eq $unitemp)
	{  $data[$x1]=~s/ +/ /g;
	   $data[$x2]=~s/ +/ /g;
	   my @copy;   # array of similar items are created if the property is same 
	   my $itr;          
	   
	   if(@copy=($data[$x2]=~/&(.*?)&/g))
	   {   $inc++;
	       $itr=0;
	       if( $data[$x1]=~/&(.*?)&/)
	       {   $data[$x1]=~s/#%(.*?)%#//g;
		   $data[$x1]=~s/\s+$//; 	      
		   if(($data[$x1]=~s/&(.*?)&/"&#%$inc%# $copy[$itr] $1#_".$itr++."_#&"/ge)) #count of the occurence of the property is s#tored while each time the redundant similar data is removed from the config terms 
		   { 
		       $data[$x1]=~s/#_(.*?)_#//g;
		       $data[$x1]=~s/\s+$//;
		   }
		   undef $data[$x2];
		   
	       }
	   }
	   elsif(($data[$x1] eq $data[$x2])&&($data[$x1] ne ''))       # check for similarity apart from the number of increment done       
	   { 	    if(($data[$x1]=~/#%(.*?)%#/)&&($data[$x2]=~/#%(.*?)%#/))
		    {
			
			($n1)=$data[$x1]=~/#%(.*?)%#/;
			($n2)=$data[$x2]=~/#%(.*?)%#/;
			$n3=$n1+$n2;
			$data[$x1]=~s/#%(.*?)%#/#%\Q$n3\E%#/;
			undef $data[$x2];
			$n3=0;
			
		    }
		    else{

			$data[$x1].="#%2%#";
			undef $data[$x2]; # after the match is counted that particular data is undefined from the array

		    }	       
	   }
	   
	   elsif(defined ($data[$x1])&&(defined $data[$x2])) #elimination check to avoid undefined loop over
	   {
	       if(($n1)=$data[$x1]=~/#%(.*?)%#/)       
		   
	       {
		   $n3=$n1+1;
	       }		 
	       if(($n2)=$data[$x2]=~/#%(.*?)%#/)
	       {
		   $n3=$n2+1;
	       }		 
	       if($n3!=0)
	       {$data[$x1]=~s/#%(.*?)%#//;
		$data[$x1].="#%".$n3."%#";
		undef $data[$x2]; 
		$n3=0;
	       }
	   }

	}

    }
    $inc=1;
}
# till now the redundant strings are retained with in the configuration 
# NOTE : If this data is needed it can be used from the array at this point 

for (my $x1=0; $x1<$datasize;$x1++) {
    for(my $x2=0;$x2<$datasize;$x2++) {
#loop to remove all the recurring data for clean and clear display
	if(($data[$x1] ne '') &&($data[$x2] ne ''))
{
    if($x1 != $x2)
{
    $t1=$data[$x1];
    $t2=$data[$x2];
    $t1=~s/#%(.*?)%#//;     # removing all type of subtitutes used
    $t2=~s/#%(.*?)%#//;
    $t1=~s/&(.*?)&//g;
    $t1=~s/\^(.*?)\^//g; 
    $t2=~s/&(.*?)&//g;
    $t2=~s/\^(.*?)\^//g; 
    
    $t1=~s/\s+$//;
    $t2=~s/\s+$//;
    $t1=~s/^\s+//;
    $t2=~s/^\s+//;
    $t1=~s/ +/ /g;
    $t2=~s/ +/ /g;
    if($t1 eq $t2)
    {		($m1)=$data[$x1]=~/#%(.*?)%#/;  #retaining the total count of occurances 
		($m2)=$data[$x2]=~/#%(.*?)%#/;
		$m3=$m1+$m2;
		$data[$x1]=~s/\s+$//;
		$data[$x1]=~s/#%(.*?)%#//;
		$data[$x1].='#%'.$m3.'%#';
		undef $data[$x2];
		$m3=0;
		
    }
}

}
    }
}
#final list creation 
my $ff,$gg;
foreach ( (@data))
{   if (defined $_)
    {
	($ff)=$_=~/(&.*?&)/;
 	($gg)=$ff=~/(#%.*?%#)/;
	$_=~s/\^.*?\^/^^/g;
	$_=~s/\s*&.*?&\s*/ ^^ /g;
	print "$_";
	print "$gg\n";
    }
}

