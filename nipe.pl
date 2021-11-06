#!/usr/bin/env perl

use 5.018;
use strict;
use warnings;
use JSON;
use Try::Tiny;
use HTTP::Tiny;
use lib "./lib/";
use Nipe::Engine::Stop;
use Nipe::Engine::Start;
use Nipe::Engine::Restart;
use Nipe::Utils::Status;
use Nipe::Utils::Helper;
use Nipe::Utils::Install;
use Gtk3 -init;
use Glib ('TRUE','FALSE');

my $window = Gtk3::Window->new('toplevel');
my $listmodel = Gtk3::ListStore->new('Glib::String');
my $row_count = 0;
my $menubar = create_menubar();
my $contentgrid = Gtk3::Grid->new();

my $lblService = Gtk3::Label->new('Nipe service ');
my $btnService = Gtk3::ToggleButton->new_with_label('Start/Stop');

my $statusbar = Gtk3::Statusbar->new();
my $context_id = $statusbar->get_context_id('statusbar');
my $maingrid = Gtk3::Grid->new();
my $listgrid = Gtk3::Grid->new();
my $view = Gtk3::TreeView->new($listmodel);

my $commands = {
	stop => "Nipe::Engine::Stop",
	start => "Nipe::Engine::Start",
	status => "Nipe::Utils::Status",
	restart => "Nipe::Engine::Restart",
	install => "Nipe::Utils::Install",
	help => "Nipe::Utils::Helper"
};


sub main {
	my $argument = $ARGV[0];

	if($argument){
		die "Nipe must be run as root.\n" if $> != 0;

		if($argument ne 'gui')
		{
			try {
				my $exec = $commands -> {$argument} -> new();
				if ($exec ne "1") {
					print $exec;
				}
			}

			catch {
				print "\n[!] ERROR: this command could not be run\n\n";
			};

			return 1;
		}
		else {
			gui();
		}
	}

	return print Nipe::Utils::Helper -> new();	
}

main();
exit;

##############################DESIGN################################

sub gui {
	$window->set_title('NIPE');
	$window->set_default_size(400,200);
	$window->signal_connect('key-press-event' => \&do_key_press_event);
	$window->signal_connect('destroy'=>sub {Gtk3->main_quit;});

	$contentgrid->set_column_spacing(5);
	$contentgrid->set_column_homogeneous(TRUE);
	$contentgrid->set_row_homogeneous(TRUE);
	$contentgrid->set_column_spacing(30);
	$contentgrid->attach($lblService,0,0,1,1);

	$btnService->signal_connect('toggled', \&toggled_cb);
	$contentgrid->attach_next_to($btnService, $lblService, 'right', 1, 1);
	$contentgrid->attach($statusbar, 0, 1, 2, 1);

	$maingrid->attach($menubar,0,0,1,1);
	$maingrid->attach($contentgrid, 0, 1, 2, 1);

	my $cell = Gtk3::CellRendererText->new();
	my $col = Gtk3::TreeViewColumn->new_with_attributes('Log',$cell,'text' => 0);
	$col->set_fixed_width(400);

	$view->append_column($col);
	$listgrid->add($view);
	$maingrid->attach($listgrid, 0, 2, 3, 2);
	$window->add($maingrid);

	$window->show_all();

	Gtk3->main();	
}

####################################################################

#############################METHODS################################

sub create_menubar {
	my $menubar=Gtk3::MenuBar->new();
	my $menubar_item=Gtk3::MenuItem->new('Options');

	$menubar->insert($menubar_item,0);

	my $menu=Gtk3::Menu->new();
	my $itemInstall=Gtk3::MenuItem->new('Install');
	my $itemRestart=Gtk3::MenuItem->new('Restart');
	my $itemAbout=Gtk3::MenuItem->new('About');
	my $itemExit=Gtk3::MenuItem->new('Quit');

	$itemInstall->signal_connect('activate'=>\&install_cb);
	$itemRestart->signal_connect('activate'=>\&restart_cb);
	$itemAbout->signal_connect('activate'=>\&about_cb);
	$itemExit->signal_connect('activate'=> sub {Gtk3->main_quit();});

	$menu->insert($itemInstall,0);
	$menu->insert($itemRestart,1);
	$menu->insert($itemAbout,2);
	$menu->insert($itemExit,3);

	$menubar_item->set_submenu($menu);

	return $menubar;
}

sub install_cb {
	&command('install');
}

sub restart_cb {
	&command('restart');
}

sub about_cb {
	my $aboutdialog = Gtk3::AboutDialog->new();
	my @authors = ('oleitao and Github Community');
	
	$aboutdialog->set_program_name('Nipe');
	$aboutdialog->set_copyright("Copyright \xa9 2021 oleitao");
	$aboutdialog->set_authors(\@authors);
	$aboutdialog->set_website('https://github.com/oleitao');
	$aboutdialog->set_website_label('Github');	
	$aboutdialog->set_title('');
	
	$aboutdialog->signal_connect('response'=>\&on_close);

	$aboutdialog->show();
}

sub on_close {
	my ($aboutdialog) = @_;
	$aboutdialog->destroy();
}

sub command {
	my $arg = $_[0];
	try {
		my $exec = $commands -> {$arg} -> new();
		if ($exec ne "1") {
			print $exec;
		}
	}

	catch {
		print "\n[!] ERROR: this command could not be run\n\n";
	};
}


sub getIP {
	my $apiCheck = "https://check.torproject.org/api/ip";
	my $request = HTTP::Tiny -> new -> get($apiCheck);
	my $checkIp;
	
	if ($request -> {status} == 200) {
		my $data = decode_json ($request -> {content});

		$checkIp  = $data -> {"IP"};

		return $checkIp;
	}
}

sub getTor {
	my $apiCheck = "https://check.torproject.org/api/ip";
	my $request = HTTP::Tiny -> new -> get($apiCheck);
	my $checkTor;
	
	if ($request -> {status} == 200) {
		my $data = decode_json ($request -> {content});

		$checkTor = $data -> {"IsTor"} ? "activated" : "disabled";

		return $checkTor;
	}
}

sub toggled_cb {
	my $add_iter = $listmodel->append();

	if ($btnService->get_active()) {
		#$spinner->start();
		# we push a message onto the statusbar's stack
		#$statusbar->push($context_id, 'Status: starting ...');
		#$statusbar->push($context_id, 'Ip: 1');

		
		#&command('start');
		&command('status');

		#my $local_ip_address = get_local_ip_address();
		#print "test" . $local_ip_address;

		$listmodel->set($add_iter, 0 => "Started IP: " . &getIP() . ". Tor network status: " . &getTor());
	}
	else
	{
		#$spinner->stop();
		#$statusbar->push($context_id, 'Stoping ...');
		#$statusbar->push($context_id, 'Ip: 2');
		
		
		#&command('stop');
		&command('status');

		$listmodel->set($add_iter, 0 => "Status: stoped ");
	}

	$row_count++;
}

####################################################################