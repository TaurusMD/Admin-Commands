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
	/*
		Print Colour Chat: print_colour_default

		Prints a default yellow colour generally, green could
		be used in a say text message here
	*/
	print_colour_default = 0,

	/*
		Print Colour Chat: print_colour_grey

		Prints a grey colour of the spectators team in a 
		say text message (Green can be used)
	*/
	print_colour_grey = 33,

	/*
		Print Colour Chat: print_colour_red

		Prints a red colour of the terrorists team in a 
		say text message (Green can be used)
	*/
	print_colour_red,

	/*
		Print Colour Chat: print_colour_blue

		Prints a blue colour of the counter-terrorists
		team in a say text message (Green can be used)
	*/
	print_colour_blue
};

// Admin command target (Values between 1 - 32 are for player index)
enum ( )
{
	/*
		Admin Command Target: ACT_EVERYONE

		This value is used to execute a certain command on all players
		who can have that certain command executed on
	*/
	ACT_EVERYONE = 0,

	/*
		Admin Command Target: ACT_T

		This value is used to execute a certain command on players in
		the terrorist team that can have that certain command executed
		on
	*/
	ACT_T = 33,

	/*
		Admin Command Target: ACT_CT

		This value is used to execute a certain command on players in
		the counter-terrorist team that can have that certain command
		executed on
	*/
	ACT_CT,

	/*
		Admin Command Target: ACT_SPECTATOR

		This value is used to execute a certain command on players in
		the spectator team that can have that certain command executed
		on
	*/
	ACT_SPECTATOR
};

// Authentication information - Function: GetAuthenticationInfo( )
enum _:AuthenticationInfo( )
{
	/*
		Authentication Information: AI_NAME

		This is an index for a function so it returns specified player's
		in-game nickname (formats the string to player name)
	*/
	AI_NAME = 0,

	/*
		Authentication Information: AI_AUTHID

		This is an index for a function so it returns specified player's
		steam_id or valve_id whatever (formats the string to player authid)
	*/
	AI_AUTHID,

	/*
		Authentication Information: AI_AUTHID

		This is an index for a function so it returns specified player's
		IP without port (formats the string to player IP without port)
	*/
	AI_IP
};

// Integers
new g_iMaxPlayers;

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

		v1.0.0 - First release - DATE / DAY (In Development)
		- Basic and most important commands

	=========================================================================== */

	/* ===========================================================================
		
		-----------------
		-*- Todo List -*-
		-----------------

		Todos are marked with 4 different characters with different meaning,
		on every new version, this todo list is removed and probably added to
		the next version changelog, new entries here are based on testing the
		plugin in a test server or suggestions from Jailbreak players

		[ - ] -> Not implemented (Pending)
		[ + ] -> Implemented, completely done and tested
		[ * ] -> Implemented, completely done but not tested
		[ x ] -> Cancelled
		
		Date: N/A - Day: N/A

	=========================================================================== */

	// Register our plugin
	register_plugin( "Admin Commands", PLUGIN_VERSION, "Taurus" );

	// Make servers using this plugin easier to find
	register_cvar( "ac_version", PLUGIN_VERSION, FCVAR_SERVER | FCVAR_SPONLY );
	set_cvar_string( "ac_version", PLUGIN_VERSION );

	// Register dictionary
	register_dictionary_coloured( "admin_commands.txt" );

	// Get maximum players (counting purposes :P)
	g_iMaxPlayers = get_maxplayers( );

	// Hamsandwich
	RegisterHam( Ham_Spawn, "player", "fw_Spawn_Post", true );
	RegisterHam( Ham_Killed, "player", "fw_Killed_Pre" );
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
register_dictionary_color( const szFileName[ ] )
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