requires "Dist::Zilla::Role::InstallTool" => "0";
requires "Dist::Zilla::Role::MetaProvider" => "0";
requires "List::AllUtils" => "0";
requires "Moose" => "0";
requires "namespace::autoclean" => "0";
requires "perl" => "5.008001";
requires "strict" => "0";
requires "utf8" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Dist::Zilla::Tester" => "0";
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec::Functions" => "0";
  requires "JSON" => "2";
  requires "List::Util" => "0";
  requires "Params::Util" => "0";
  requires "Path::Class" => "0";
  requires "Sub::Exporter" => "0";
  requires "Test::Deep" => "0";
  requires "Test::More" => "0.88";
  requires "YAML::Tiny" => "0";
  requires "lib" => "0";
  requires "version" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "0";
  recommends "CPAN::Meta::Requirements" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.17";
};

on 'develop' => sub {
  requires "Dist::Zilla" => "5";
  requires "Dist::Zilla::PluginBundle::DAGOLDEN" => "0.060";
  requires "File::Spec" => "0";
  requires "File::Temp" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Test::CPAN::Meta" => "0";
  requires "Test::More" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::Spelling" => "0.12";
};
