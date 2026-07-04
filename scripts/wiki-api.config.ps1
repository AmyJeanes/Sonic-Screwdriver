@{
    WikiBaseUrl = 'https://github.com/AmyJeanes/Sonic-Screwdriver/wiki'
    Categories = @(
        @{ Title = 'Animation Reference'; File = 'Animation-Reference'; Roots = @('sonicsd_anim') }
        @{ Title = 'Functions Reference'; File = 'Functions-Reference'; Kind = 'functions'; Class = 'SonicSD' }
        @{ Title = 'swep_sonicsd';        File = 'swep_sonicsd';        Kind = 'functions'; Class = 'swep_sonicsd'; Source = 'lua/weapons/swep_sonicsd' }
        @{ Title = 'Hooks Reference';     File = 'Hooks-Reference';     Kind = 'hooks'; EntityListen = 'SWEP:AddHook(name, id, func)' }
        @{ Title = 'ConVars Reference';   File = 'ConVars-Reference';   Kind = 'convars' }
    )
    OwnedPrefix = @('sonicsd_')
}
