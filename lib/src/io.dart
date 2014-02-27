part of pub_proxy_server;

void ensureDirectoryExist(String dir){
  var d = new Directory(dir);
  if (!d.existsSync()) d.createSync(recursive: true);
}



Future<bool> _checkSum(File file, String checsum){
  print("_checkSum file $file");
  if (checsum == null) return new Future.value(true);
  return new Future.value(true);
}

Future run(app,args,{String workingDirectory, runInShell: true, List<int> exitCodes}){
  if (exitCodes == null) exitCodes = [0];
  return Process.run(app, args, runInShell: runInShell, workingDirectory: workingDirectory).then((result) {
    //stdout.write(result.stdout);
    //stderr.write(result.stderr);
    if (exitCodes.contains(result.exitCode)){
      print("$app $args exit code ${result.exitCode}");
    }
    else {
      throw ("$app $args failed with exit code ${result.exitCode}");
    }
  });
}