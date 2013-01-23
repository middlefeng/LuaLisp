

do
	local old_string = _ENV.string
	local old_io = _ENV.io
	local old_os = _ENV.os

	_ENV = {}
	_ENV.string = old_string
	_ENV.io = old_io
	_ENV.os = old_os
end


function to_uri(s, prefix)
	prefix = prefix or "smb:"
	s = string.gsub(s, "\\", "/")
	s = prefix .. s
	return s
end


function uri()
	local s = io.read("*l")
	return to_uri(s)
end


function mount(uri, name)
	os.execute("mkdir /Volumes/" .. name)
	os.execute("mount -t smbfs " .. uri .. " /Volumes/" .. name)
end


function mount_build()
	mount("//dfeng@ps-bj-fs.pac.adobe.com/Builds/Photoshop/Deblur",
		  "Deblur")
end


function mount_test()
	mount("//dfeng@di-asc-fs/Builds/Photoshop/13.0/Deblur/Builds/TestFiles",
		  "TestFiles")
end



return _ENV