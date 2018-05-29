/* ===========================================================================
	
	----------------------
	-*- Admin Commands -*-
	----------------------

	(c) 2018 - Taurus
	Website: https://genjero.com

=========================================================================== */

// Includes
#include < amxmodx >
#include < amxmisc >
#include < cstrike >
#include < fakemeta >
#include < fun >
#include < hamsandwich >

// Semicolon coding style
#pragma semicolon 1;

// Turns stuff into bitsums
#define TurnIntoBit(%1)	( 1 << %1 )

// Bitsums!
#define SetBit(%1,%2)	( %1 |= TurnIntoBit( %2 - 1 ) )
#define ClearBit(%1,%2)	( %1 &= ~ TurnIntoBit( %2 - 1 ) )
#define CheckBit(%1,%2)	( %1 & TurnIntoBit( %2 - 1 ) )

// Checks whether a player is valid or not
#define is_user_valid(%1)			( 1 <= %1 <= g_iMaxPlayers )
#define is_user_valid_connected(%1)	( is_user_valid( %1 ) && CheckBit( g_bIsConnected, %1 ) )
#define is_user_valid_alive(%1)		( is_user_valid( %1 ) && CheckBit( g_bIsAlive, %1 ) )

// Version details is in the plugin_init( ) comment block before plugin registration
#define PLUGIN_VERSION	"1.0.0"

// Chat colours
enum ( )
{
	print_colour_default = 0,
	print_colour_grey = 33,
	print_colour_red,
	print_colour_blue
};

// Authentication information - Function: GetAuthenticationInfo( )
enum _:AuthenticationInfo( )
{
	AI_NAME = 0,
	AI_AUTHID,
	AI_IP
};

// Admin command target
enum ( )
{
	ACT_ALL = 0,
	ACT_T,
	ACT_CT
};

// Admin command target skip
enum ( )
{
	ACTS_NO = 0,
	ACTS_BOTS,
	ACTS_DEAD
}


// Integers
new g_iMaxPlayers;
new g_iShowActivity;

// Bitsums
new g_bIsConnected;
new g_bIsAlive;

// Plugin starts!
public plugin_init( )
{
	/* ===========================================================================
		
		---------------------------
		-*- Version Information -*-
		---------------------------

		Version string is divided into three parts:
		A- Major version number -> Major changes, new functions and updates
		B- Minor version number -> Better codes, minor optimisations 
		C- Beta version number -> Brief updates and bug fixes

		- If major version number changes, both minor and beta reset to 0
		- If minor version number changes, only beta resets to 0
		- If beta version number changes, nothing resets

		This plugin supports only AMX Mod X 1.8.2, so compiling this plugin
		with AMX Mod X 1.8.3 compiler will throw serious errors, and I will
		not support it, unless a feature in my plugin requires it!

		-----------------
		-*- Changelog -*-
		-----------------

		v1.0.0 - First release - 29-05-2018 / Tuesday (In Development)
		- Created the basic structure of the plugin
		- Added the command "ac_health"

	=========================================================================== */

	/* ===========================================================================
		
		-----------------
		-*- Todo List -*-
		-----------------

		Todos are marked with 4 different characters with different meaning,
		on every new version, this todo list is removed and probably added to
		the next version changelog, new entries here are based on testing the
		plugin in a test server or suggestions from beta testers

		[ - ] -> Not implemented (Pending)
		[ + ] -> Implemented, completely done and tested
		[ * ] -> Implemented, completely done but not tested
		[ x ] -> Cancelled
		
		Date: 29-05-2018 - Day: Tuesday
		- [ - ] Add the command "ac_armour" - ADMIN_LEVEL_A
		- [ - ] Add the command "ac_noclip" - ADMIN_LEVEL_A
		- [ - ] Add the command "ac_godmode" - ADMIN_LEVEL_A
		- [ - ] Add the command "ac_money" - ADMIN_LEVEL_A

	=========================================================================== */

	// Register our plugin
	register_plugin( "Admin Commands", PLUGIN_VERSION, "Taurus" );

	// Make servers using this plugin easier to find
	register_cvar( "ac_version", PLUGIN_VERSION, FCVAR_SERVER | FCVAR_SPONLY );
	set_cvar_string( "ac_version", PLUGIN_VERSION );

	// Register dictionary
	register_dictionary_colour( "admin_commands.txt" );

	// Get maximum players (counting purposes :P)
	g_iMaxPlayers = get_maxplayers( );

	// Console commands
	register_concmd( "ac_health", "ConCommand_Health", ADMIN_LEVEL_A, "<nick | #userid | authid | @team> <#HP>" );

	// Hamsandwich
	RegisterHam( Ham_Spawn, "player", "fw_Spawn_Post", true );
	RegisterHam( Ham_Killed, "player", "fw_Killed_Pre" );
}

public plugin_cfg( )
{
	// Retrieve show activity
	new cvar_show_activity = get_cvar_pointer( "amx_show_activity" );

	// If it does not equal to 0, update our global param :D
	if( cvar_show_activity )
		g_iShowActivity = get_pcvar_num( cvar_show_activity );
}

public client_putinserver( id )
{
	// Set bitsum
	SetBit( g_bIsConnected, id );

	// Clear bitsum
	ClearBit( g_bIsAlive, id );
}

public client_disconnect( id )
{
	// Clear bitsum
	ClearBit( g_bIsConnected, id );
	ClearBit( g_bIsAlive, id );
}

public ConCommand_Health( id, iAccess, command_id )
{
	// No access?
	if( !cmd_access( id, iAccess, command_id, 3 ) )
		return PLUGIN_HANDLED;

	// Retrieve arguments
	new szTarget[ 32 ], szHealth[ 8 ], temp_id, current_health;
	read_argv( 1, szTarget, charsmax( szTarget ) );
	read_argv( 2, szHealth, charsmax( szHealth ) );

	// Regardless of the target, define new health
	new new_health = str_to_num( szHealth );

	// What's our argument
	if( szTarget[ 0 ] == '@' )
	{
		// Declare and define some variables
		new iPlayers[ 32 ], iCount, iTargetTeam = GetTeamTarget( szTarget, iPlayers, iCount, ACTS_DEAD );

		// No players could be targeted
		if( !iCount )
		{
			console_print( id, "%L", id, "CMD_ERROR_NO_PLAYERS" );
			return PLUGIN_HANDLED;
		}

		// Do command on players
		for( new iLoop = 0; iLoop < iCount; iLoop ++ )
		{
			// Save into a variable to prevent re-indexing
			temp_id = iPlayers[ iLoop ];

			// Player is not in-game?
			if( !CheckBit( g_bIsConnected, temp_id ) )
				continue;

			// Skip immunity (But allow to self)!
			if( temp_id != id && access( temp_id, ADMIN_IMMUNITY ) )
				continue;

			// Get current player's health
			current_health = get_user_health( temp_id );

			// Update player's health
			set_user_health( temp_id, current_health + new_health );
		}

		switch( iTargetTeam )
		{
			// All?
			case ACT_ALL:
			{
				// Notice message format
				switch( g_iShowActivity )
				{
					case 1: client_print_colour( 0, print_colour_default, "%L", LANG_SERVER, "CMD_HEALTH_ALL_NO_NAME", new_health );
					case 2: client_print_colour( 0, print_colour_default, "%L", LANG_SERVER, "CMD_HEALTH_ALL", GetAuthenticationInfo( id, AI_NAME ), new_health );
				}

				// Log administrative action
				Log( "ADMIN %s <%s><%s> - Gave %d HP to ALL (Players: %d)", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), new_health, iCount );
			}

			// Terrorists?
			case ACT_T:
			{
				// Notice message format
				switch( g_iShowActivity )
				{
					case 1: client_print_colour( 0, print_colour_red, "%L", LANG_SERVER, "CMD_HEALTH_T_NO_NAME", new_health );
					case 2: client_print_colour( 0, print_colour_red, "%L", LANG_SERVER, "CMD_HEALTH_T", GetAuthenticationInfo( id, AI_NAME ), new_health );
				}

				// Log administrative action
				Log( "ADMIN %s <%s><%s> - Gave %d HP to TERRORISTS (Players: %d)", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), new_health, iCount );
			}

			// Counter-Terrorists?
			case ACT_CT:
			{
				// Notice message format
				switch( g_iShowActivity )
				{
					case 1: client_print_colour( 0, print_colour_blue, "%L", LANG_SERVER, "CMD_HEALTH_CT_NO_NAME", new_health );
					case 2: client_print_colour( 0, print_colour_blue, "%L", LANG_SERVER, "CMD_HEALTH_CT", GetAuthenticationInfo( id, AI_NAME ), new_health );
				}

				// Log administrative action
				Log( "ADMIN %s <%s><%s> - Gave %d HP to COUNTER-TERRORISTS (Players: %d)", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), new_health, iCount );
			}
		}
	}
	else
	{
		temp_id = cmd_target( id, szTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF | CMDTARGET_ONLY_ALIVE );

		if( !is_user_valid_connected( temp_id ) )
			return PLUGIN_HANDLED;

		// Get current player's health
		current_health = get_user_health( temp_id );

		// Update player's health
		set_user_health( temp_id, current_health + new_health );

		// Notice message format
		switch( g_iShowActivity )
		{
			case 1: client_print_colour( 0, temp_id, "%L", LANG_SERVER, "CMD_HEALTH_PLAYER_NO_NAME", new_health, GetAuthenticationInfo( temp_id, AI_NAME ) );
			case 2: client_print_colour( 0, temp_id, "%L", LANG_SERVER, "CMD_HEALTH_PLAYER", GetAuthenticationInfo( id, AI_NAME ), new_health, GetAuthenticationInfo( temp_id, AI_NAME ) );
		}

		// Log administrative action
		Log( "ADMIN %s <%s><%s> - Gave %d HP to %s <%s><%s>", GetAuthenticationInfo( id, AI_NAME ), GetAuthenticationInfo( id, AI_AUTHID ), GetAuthenticationInfo( id, AI_IP ), new_health, GetAuthenticationInfo( temp_id, AI_NAME ), GetAuthenticationInfo( temp_id, AI_AUTHID ), GetAuthenticationInfo( temp_id, AI_IP ) );
	}

	return PLUGIN_HANDLED;
}

public fw_Spawn_Post( id )
{
	// Player is not alive?
	if( !is_user_alive( id ) )
		return;

	// Set bitsum
	SetBit( g_bIsAlive, id );
}

public fw_Killed_Pre( victim_id, attacker_id )
{
	// Victim is not in-game?
	if( !is_user_valid_connected( victim_id ) )
		return;

	// Clear bitsum
	ClearBit( g_bIsAlive, victim_id );
}

GetTeamTarget( szArgument[ ], iPlayers[ 32 ], &iCount, iSkip = ACTS_NO )
{
	// Declare variables
	new iTargetTeam, szFlags[ 4 ];

	// Check skip mode
	switch( iSkip )
	{
		case ACTS_NO: szFlags = "e";
		case ACTS_BOTS: szFlags = "ce";
		case ACTS_DEAD: szFlags = "ae";
	}

	// Execute command on all players?
	if( equali( szArgument[ 1 ], "ALL", strlen( szArgument[ 1 ] ) ) )
	{
		// Update skip mode
		switch( iSkip )
		{
			case ACTS_NO: szFlags = "";
			case ACTS_BOTS: szFlags = "c";
			case ACTS_DEAD: szFlags = "a";
		}

		// Set target team to ALL!
		iTargetTeam = ACT_ALL;

		// Count all players with skip flags
		get_players( iPlayers, iCount, szFlags );
	}

	// Execute command on terrorists?
	if( equali( szArgument[ 1 ], "TERRORIST", strlen( szArgument[ 1 ] ) ) )
	{
		// Set target team to TERRORISTS
		iTargetTeam = ACT_T;

		// Count all players in terrorist team with skip flags
		get_players( iPlayers, iCount, szFlags, "TERRORIST" );
	}

	// Execute command on COUNTER-TERRORISTS
	if( equali( szArgument[ 1 ], "CT" ) || equali( szArgument[ 1 ], "C" ) || equali( szArgument[ 1 ], "COUNTER" ) )
	{
		// Set target team to COUNTER-TERRORISTS
		iTargetTeam = ACT_CT;

		// Count all players in counter-terrorist team with skip flags
		get_players( iPlayers, iCount, szFlags, "CT" );
	}

	// Return target team value
	return iTargetTeam;
}

// Formats a string to player authentication information as defined
GetAuthenticationInfo( id, iAuthenticationInfo )
{
	// Declare a variable
	static szAuthenticationInfo[ 32 ];

	// What is the authentication info defined?
	switch( iAuthenticationInfo )
	{
		// Get player's name
		case AI_NAME: get_user_name( id, szAuthenticationInfo, charsmax( szAuthenticationInfo ) );

		// Get player's authentication id
		case AI_AUTHID: get_user_authid( id, szAuthenticationInfo, charsmax( szAuthenticationInfo ) );

		// Get player's IP without port
		case AI_IP: get_user_ip( id, szAuthenticationInfo, charsmax( szAuthenticationInfo ), true );
	}

	// Return our formatted string
	return szAuthenticationInfo;
}

// Formats a message and logs into a file designed for events of this plugin
Log( const szFormat[ ], any:... )
{
	// Declare and define some variables
	static szMessage[ 256 ], szDate[ 16 ], szFileName[ 32 ];
	vformat( szMessage, charsmax( szMessage ), szFormat, 2 );
	format_time( szDate, charsmax( szDate ), "%Y-%m-%d" );
	formatex( szFileName, charsmax( szFileName ), "AC_%s.log", szDate );

	// Log our message to the file! :)
	log_to_file( szFileName, "%s", szMessage );
}

// Prefix for the plugin
#define PLUGIN_PREFIX "^1[^4AC^1]"

// Prints a coloured say text message
client_print_colour( id, colour_id, const szFormat[ ], any:... )
{
	if( id && !is_user_valid_connected( id ) )
		return false;
	
	static const szTeam[ ][ ] =
	{
		"",
		"TERRORIST",
		"CT"
	};
	
	new szMessage[ 192 ], iParameters = numargs( );

	if( id )
	{
		if( iParameters == 3 )
		{
			copy( szMessage, charsmax( szMessage ), szFormat );
			format( szMessage, charsmax( szMessage ), "%s %s", PLUGIN_PREFIX, szMessage );
		}
		else
		{
			vformat( szMessage, charsmax( szMessage ), szFormat, 4 );
			format( szMessage, charsmax( szMessage ), "%s %s", PLUGIN_PREFIX, szMessage );
		}
		
		if( colour_id > print_colour_grey )
		{
			if( colour_id > print_colour_blue )
				colour_id = id;
			else
				send_team_info( id, colour_id, szTeam[ colour_id - print_colour_grey ] );
		}
		
		send_say_text( id, colour_id, szMessage );
	}
	else
	{
		new iPlayers[ 32 ], iCount;
		get_players( iPlayers, iCount, "ch" );
		
		if( !iCount )
			return false;
		
		new iMLCount, iLoop, iInnerLoop;
		new Array:aStoreML = ArrayCreate( );
		
		if( iParameters >= 5 )
		{
			for( iInnerLoop = 3; iInnerLoop < iParameters; iInnerLoop ++ )
			{
				if( getarg( iInnerLoop ) == LANG_PLAYER )
				{
					iLoop = 0;
					
					while( ( szMessage[ iLoop ] = getarg( iInnerLoop + 1, iLoop ++ ) ) ) { }
					
					if( GetLangTransKey( szMessage ) != TransKey_Bad )
					{
						ArrayPushCell( aStoreML, iInnerLoop ++ );
						iMLCount ++;
					}
				}
			}
		}
		
		if( !iMLCount )
		{
			if( iParameters == 3 )
			{
				copy( szMessage, charsmax( szMessage ), szFormat );
				format( szMessage, charsmax( szMessage ), "%s %s", PLUGIN_PREFIX, szMessage );
			}
			else
			{
				vformat( szMessage, charsmax( szMessage ), szFormat, 4 );
				format( szMessage, charsmax( szMessage ), "%s %s", PLUGIN_PREFIX, szMessage );
			}
			
			if( 0 < colour_id < print_colour_blue )
			{
				if( colour_id > print_colour_grey )
					send_team_info( 0, colour_id, szTeam[ colour_id - print_colour_grey ] );
				
				send_say_text( 0, colour_id, szMessage );
				return true;
			}
		}
		
		if( colour_id > print_colour_blue )
			colour_id = 0;
		
		for( -- iCount; iCount >= 0; iCount -- )
		{
			id = iPlayers[ iCount ];
			
			if( iMLCount )
			{
				for( iInnerLoop = 0; iInnerLoop < iMLCount; iInnerLoop++ )
					setarg( ArrayGetCell( aStoreML, iInnerLoop ), _, id );
				
				vformat( szMessage, charsmax( szMessage ), szFormat, 4 );
				format( szMessage, charsmax( szMessage ), "%s %s", PLUGIN_PREFIX, szMessage );
			}
			
			if( colour_id > print_colour_grey )
				send_team_info( id, colour_id, szTeam[ colour_id - print_colour_grey ] );
			
			send_say_text( id, colour_id, szMessage );
		}
		
		ArrayDestroy( aStoreML );
	}
	
	return true;
}

// Sends a team info message
send_team_info( receiver_id, sender_id, szTeam[ ] )
{
	static msgTeamInfo;

	if( !msgTeamInfo )
		msgTeamInfo = get_user_msgid( "TeamInfo" );
	
	message_begin( receiver_id ? MSG_ONE : MSG_ALL, msgTeamInfo, _, receiver_id );
	write_byte( sender_id );
	write_string( szTeam );
	message_end( );
}

// Sends a say text message
send_say_text( receiver_id, sender_id, szMessage[ ] )
{
	static msgSayText;

	if( !msgSayText )
		msgSayText = get_user_msgid( "SayText" );
	
	message_begin( receiver_id ? MSG_ONE : MSG_ALL, msgSayText, _, receiver_id );
	write_byte( sender_id ? sender_id : receiver_id );
	write_string( szMessage );
	message_end( );
}

// Registers a coloured dictionary
register_dictionary_colour( const szFileName[ ] )
{
	if( !register_dictionary( szFileName ) )
		return false;

	new szDirectory[ 128 ];
	get_localinfo( "amxx_datadir", szDirectory, charsmax( szDirectory ) );
	format( szDirectory, charsmax( szDirectory ), "%s/lang/%s", szDirectory, szFileName );

	new iFile = fopen( szDirectory, "rt" );

	if( !iFile )
	{
		log_amx( "[AMXX] Failed to open file: %s", szDirectory );
		return false;
	}

	new TransKey:iKey, buffer[ 512 ], szLanguage[ 3 ], szKey[ 64 ], szTranslation[ 256 ];

	while( iFile && !feof( iFile ) )
	{
		fgets( iFile, buffer, charsmax( buffer ) );
		trim( buffer );

		if( buffer[ 0 ] == '[' )
			strtok( buffer[ 1 ], szLanguage, charsmax( szLanguage ), buffer, 1, ']' );
		else if( buffer[ 0 ] )
		{
			strbreak( buffer, szKey, charsmax( szKey ), szTranslation, charsmax( szTranslation ) );

			iKey = GetLangTransKey( szKey );

			if( iKey != TransKey_Bad )
			{
				while( replace( szTranslation, charsmax( szTranslation ), "!g", "^4" ) ) { /* Keep Looping! */ }
				while( replace( szTranslation, charsmax( szTranslation ), "!t", "^3" ) ) { /* Keep Looping! */ }
				while( replace( szTranslation, charsmax( szTranslation ), "!n", "^1" ) ) { /* Keep Looping! */ }

				AddTranslation( szLanguage, iKey, szTranslation[ 2 ] );
			}
		}
	}

	fclose( iFile );
	return true;
}