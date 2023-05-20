# NbMavenize
The script was written to migrate [JJazzLab](https://github.com/jjazzboss/JJazzLab-X), an Ant-based Netbeans platform application (~70 modules) to Maven.

The script expects the Netbeans platform projects to have a standard structure:

```
AntApp/
  nbproject/
  branding/
  module1/
     manifest.mf
     src/
     nbproject/
        project.xml
        project.properties
        ...
     ...
  module2/
     ...
  ...

MavenApp/
  pom.xml
  application/
     pom.xml
     ...
  branding/
     ...
  ...
```

# Usage
Example: `nbMavenize.sh AntApp/module2 MavenApp`

The imported module is stored in the `modules` subdirectory of the Maven parent project. 

The main operations are:

- Copy module source and resource files
- Copy and adapt module `manifest.mf` file
- Update `parent/pom.xml` and `application/pom.xml`
- Create the module `pom.xml` file with the appropriate public packages and dependencies

Note that the parent and application `pom.xml` files are updated only if necessary, so it's safe to run the script repeatedly. 

# Limitations
The script does **not** handle all possible cases, though it scans the source project to inform you about possible `MANUAL ACTIONS NEEDED` to be performed post-script (e.g. for Ant "library wrapper modules", or when the `release` subdirectory is used).

Other tasks you must perform yourself: 
- Add dependencies for unit tests
- If an Ant module uses customized compiler settings (defined in `module/nbproject/project.properties`, e.g. `javac.compilerargs`), you need to manually update the corresponding pom file to configure the `maven-compiler-plugin` accordingly.
- Copy the `core` and  `modules` subdirectories from `AntApp/branding` to `MavenApp/branding/src/main/nbm-branding`
- ...


# Useful links 
I learnt Maven while doing this migration, I found those links very useful:

- https://maven.apache.org/pom.html  
- https://github.com/gephi/gephi   



