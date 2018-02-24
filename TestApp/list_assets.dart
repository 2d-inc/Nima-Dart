import "dart:io";

void main()
{
	var myDir = new Directory("assets/");
	myDir.list(recursive: true, followLinks: false)
		.listen((FileSystemEntity entity) 
		{
      		print("    - " + entity.path);
    	});
}