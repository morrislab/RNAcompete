#!/usr/bin/perl

#---------------------------------------------------------
# load_args
#---------------------------------------------------------
sub load_args (\@)
{
  my @args = @{@_[0]};

  my %result;

  my $num_args = @args;

  for (my $current_arg = 0; $current_arg < $num_args; $current_arg++)
  {
    my $arg = $args[$current_arg];

    if ($arg =~ /-([^\s]+)/)
    {
      my $arg_name = $1;

      my $next_arg = $args[$current_arg + 1];

      if ($next_arg =~ /-([^\s])/ || length($next_arg) == 0)
      {
	$result{$arg_name} = "1";
      }
      else
      {
	$result{$arg_name} = $next_arg;
	$current_arg++;
      }

      #print "load_args: result{$arg_name}=$result{$arg_name}\n";
    }
  }

  return %result;
}

#---------------------------------------------------------
# get_arg
#---------------------------------------------------------
sub get_arg ($$\%)
{
  my ($arg, $default, $str_args) = @_;
  my %args = %$str_args;

  if (length($args{$arg}) > 0) { return $args{$arg}; }
  else { return $default; }
}

1
