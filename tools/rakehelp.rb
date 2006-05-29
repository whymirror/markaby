
def make(makedir)
    Dir.chdir(makedir) do
        sh 'make'
    end
end


def extconf(dir)
    Dir.chdir(dir) do ruby "extconf.rb" end
end


def setup_tests
    Rake::TestTask.new do |t|
        t.libs << "test"
        t.test_files = FileList['test/test*.rb']
        t.verbose = true
    end
end


def setup_clean otherfiles
    files = ['build/*', '**/*.o', '**/*.so', '**/*.a', 'lib/*-*', '**/*.log'] + otherfiles
    CLEAN.include(files)
end


def setup_rdoc files
    Rake::RDocTask.new do |rdoc|
        rdoc.rdoc_dir = 'doc/rdoc'
        rdoc.options << '--line-numbers'
        rdoc.rdoc_files.add(files)
    end
end


def setup_extension(dir, extension)
    ext = "ext/#{dir}"
    ext_so = "#{ext}/#{extension}.#{Config::CONFIG['DLEXT']}"
    ext_files = FileList[
    "#{ext}/*.c",
    "#{ext}/*.h",
    "#{ext}/extconf.rb",
    "#{ext}/Makefile",
    "lib"
    ] 
    
    task "lib" do
        directory "lib"
    end

    desc "Builds just the #{extension} extension"
    task extension.to_sym => ["#{ext}/Makefile", ext_so ]

    file "#{ext}/Makefile" => ["#{ext}/extconf.rb"] do
        extconf "#{ext}"
    end

    file ext_so => ext_files do
        make "#{ext}"
        cp ext_so, "lib"
    end
end


def setup_gem(pkg_name, pkg_version, author, summary, dependencies, test_file)
    pkg_version = pkg_version
    pkg_name    = pkg_name
    pkg_file_name = "#{pkg_name}-#{pkg_version}"

    spec = Gem::Specification.new do |s|
        s.name = pkg_name
        s.version = pkg_version
        s.platform = Gem::Platform::RUBY
        s.author = author
        s.summary = summary
        s.test_file = test_file
        s.has_rdoc = true
        s.extra_rdoc_files = [ "README" ]
        dependencies.each do |dep|
            s.add_dependency(*dep)
        end
        s.files = %w(README Rakefile setup.rb) +
        Dir.glob("{bin,doc,test,lib}/**/*") + 
        Dir.glob("ext/**/*.{h,c,rb}") +
        Dir.glob("examples/**/*.rb") +
        Dir.glob("tools/*.rb")
    
        s.require_path = "lib"
        s.extensions = FileList["ext/**/extconf.rb"].to_a

        s.bindir = "bin"
    end

    Rake::GemPackageTask.new(spec) do |p|
        p.gem_spec = spec
        p.need_tar = true
    end
end
