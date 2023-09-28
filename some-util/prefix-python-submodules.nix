{ lib }:
{ pname, dirSubmodules, fileSubmodules }:

let
  moduleNames = dirSubmodules ++ fileSubmodules;

  submoduleFilesList = map (x: "${x}.py") fileSubmodules;
  submoduleDirsList = map (x: "${x}/") dirSubmodules;

  submoduleFiles = lib.concatStringsSep " " (map (x: ''"${x}"'') submoduleFilesList);
  submoduleDirs = lib.concatStringsSep " " (map (x: ''"${x}"'') submoduleDirsList);
  submoduleRegex = lib.concatStringsSep ''\|'' (map (x: ''\b${x}\b'') moduleNames);
in
{
  sed = ''
    find -iname '*.py' -exec \
      sed -i \
        -e 's/^\(\s*import .*\)\(${submoduleRegex}\)\(.*\)$/\1${pname}.\2\3/' \
        -e 's/^\(\s*\)from \(${submoduleRegex}\)/\1from ${pname}.\2/' \
        '{}' '+'
  '';
  mv = ''
    mkdir src/${pname} -p
    mv ${submoduleFiles} ${submoduleDirs} \
      src/${pname}/
  '';
}
