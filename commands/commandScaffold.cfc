/**
* Create a new CommandBox Custom Command
*
* This command will create a folder in the current working directory and generate the basic files needed to begin developing a news custom command
* 
* Examples
* {code:bash}
* commandScaffold namespace="datehelp" command="file" 
* commandScaffold command="datehelp" name="Date Help Command"
* commandScaffold command="datehelp" name="Date Help Command" --doPackageLink
* {code}
*/
component {

  variables.templatePath = "/custom-command-scaffold/template/";

  /**
  * @command Name of the command you would like to create [i.e. cfconfig ]
  * @namespace Optional namespace for two-part commands  [i.e. cfformat check ]
  * @name Name of the package/module for this custom command [i.e. CFDocs Command].
  * @description Optional description of what this command does.
  * @doPackageLink Automatically links the package to the CommandBox core after creation.
  */
  function run(
    string  command       = "",
    string  namespace     = "",
    string  name          = "",
    string  description   = "",
    boolean doPackageLink = false
  ){

    if ( !command.trim().len() ) {

      print.line()
        .boldRedLine( "In order to scaffold a command, you need to provide the name of the command. Sorry." )
        .redLine( "(Otherwise we really wouldn't know what we were scaffolding.)" )
        .line();

      command = trim( ask( 'What is the name of the command you would like to build. [i.e. cfconfig]: ' ) );

      if ( !command.len() ) {
        print.line( 'Ok, exiting. Come back soon!' );
        return;
      } else {
        print.greenLine( "Thanks! On with the show! " )
          .line();
      }
    }

    if( !name.trim().len() ) {
      name = "#command# Command";
    }

    var commandNameClean = toProperSlug( command );
    var namespaceClean   = toProperSlug( namespace );
    var packageNameClean = toProperSlug( name );
    var slug = packageNameClean.left( 11 ) == 'commandbox-'
      ? packageNameClean
      : 'commandbox-#packageNameClean#';

    if( !commandNameClean.len() ){
      print.boldRedLine( 'Command name provided was not valid. Please limit names to alphanumeric characters.' );
      return;
    }

    var projectDirectory = fileSystemUtil.resolvePath( slug );

    print.line().cyanLine( "Command Project Directory: #projectDirectory#" );

    print.line().cyanLine( "Copying template over...." );

    if ( !directoryExists( projectDirectory ) )
      directoryCreate( projectDirectory  );

    var moduleConfig = fileRead( templatePath & "ModuleConfig.cfc.stub" );
    fileWrite( projectDirectory & "/ModuleConfig.cfc", moduleConfig );

    var commandsDirectory = projectDirectory & '/commands';

    if ( !directoryExists( commandsDirectory ) ){
      directoryCreate( commandsDirectory  );
    }
    
    if ( namespaceClean.len() ) {
      commandsDirectory &= '/#namespaceClean#';
      if ( !directoryExists( commandsDirectory ) ){
        directoryCreate( commandsDirectory  );
      }
    }

    var commandTemplate = fileRead( templatePath & "command.cfc.stub" );
    fileWrite( commandsDirectory & "/#commandNameClean#.cfc", commandTemplate );

    this.command( 'tokenReplace' )
      .params( 
        path = "**.cfc",
        token = "@@commandName@@",
        replacement = command
      )
      .inWorkingDirectory( projectDirectory )
      .run();

    print.line().cyanLine( "Generating box.json..." );

    this.command( 'cd #projectDirectory#' ).run( returnOutput=true );
    this.command( 'package init' )
      .params( 
        name=name,
        slug=slug,
        shortDescription=description,
        type='commandbox-modules' )
      .run();

    if( doPackageLink ){
      print.line().cyanLine( "Linking package to CommandBox Core..." );
      this.command( 'package link' ).run();
    }
    this.command( 'cd ../' ).run( returnOutput=true );

    print.line();
    print.boldYellowLine( "Custom Command Scaffolded!" );
    print.line();

    print.boldGreenLine( '**************************');
    print.greenLine( "To start developing your command, run:" );
    if( !doPackageLink ){ 
      print.greenLine( "cd #projectDirectory# && package link" );
    } else {
      print.greenLine( "cd #projectDirectory#" );
    }
    print.boldGreenLine( '**************************');
    print.line();
  }

  /**
  * Modified version of https://cflib.org/udf/toFriendlyURL by Chris Carey (ccarey@fi.net.au)
  */
  public string function toProperSlug( string str ) {

    var diacritics = [
      ["#CHR(225)##CHR(224)##CHR(226)##CHR(229)##CHR(227)##CHR(228)#", "a"],
      ["#CHR(230)#", "ae"],
      ["#CHR(231)#", "c"],
      ["#CHR(233)##CHR(232)##CHR(234)##CHR(235)#", "e"],
      ["#CHR(237)##CHR(236)##CHR(238)##CHR(239)#", "i"],
      ["#CHR(241)#", "n"],
      ["#CHR(243)##CHR(242)##CHR(244)##CHR(248)##CHR(245)##CHR(246)#", "o"],
      ["#CHR(223)#", "B"],
      ["#CHR(250)##CHR(249)##CHR(251)##CHR(252)#", "u"],
      ["#CHR(255)#", "y"],
      ["#CHR(193)##CHR(192)##CHR(194)##CHR(197)##CHR(195)##CHR(196)#", "A"],
      ["#CHR(198)#", "AE"],
      ["#CHR(199)#", "C"],
      ["#CHR(201)##CHR(200)##CHR(202)##CHR(203)#", "E"],
      ["#CHR(205)##CHR(204)##CHR(206)##CHR(207)#", "I"],
      ["#CHR(209)#", "N"],
      ["#CHR(211)##CHR(210)##CHR(212)##CHR(216)##CHR(213)##CHR(214)#", "O"],
      ["#CHR(218)##CHR(217)##CHR(219)##CHR(220)#", "U"]
    ];

    str = diacritics.reduce(
      function( result, item, index ) {
        return result.ReReplace( item[1], item[2], "all" );
      }, str
    );

    // make it all lower case (and adjust length)
    str = str.trim().lcase().left( 127 );
    // replace consecutive spaces and dashes and underscores with a single dash
    str = str.ReReplace( '[\s\-_]+', '-', 'all' );
    // remove dashes at the beginning or end of the string
    str = str.ReReplace( '(^\-+)|(\-+$)', '', 'all' );

    // replace ampersand with and
    str = str.ReReplace( '&amp;', 'and', 'all' );
    str = str.ReReplace( '&.*?;', '', 'all' );
    str = str.ReReplace( '&', 'and', 'all' );

    // remove any remaining non-word chars
    str = str.ReReplace( '[^a-z0-9\-_]', '', 'all' );

    return str;
  }
}