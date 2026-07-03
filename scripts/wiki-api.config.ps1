@{
    WikiBaseUrl = 'https://github.com/AmyJeanes/Sonic-Screwdriver/wiki'
    Categories = @(
        @{ Title = 'Animation Reference'; File = 'Animation-Reference'; Roots = @('sonicsd_anim') }
        @{ Title = 'Hooks Reference';     File = 'Hooks-Reference';     Kind = 'hooks'; EntityListen = 'SWEP:AddHook(name, id, func)' }
        @{ Title = 'ConVars Reference';   File = 'ConVars-Reference';   Kind = 'convars' }
    )
    OwnedPrefix = @('sonicsd_')
}
