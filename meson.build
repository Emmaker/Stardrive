project('dbound', 'd', version: '0.1', default_options: ['warning_level=3'])

inc = include_directories('source')
# where common_src is defined
subdir('source')

sdl = dependency('sdl-d', method: 'dub')

executable(
    'stardrive',
    common_src,
    include_directories: inc
)

executable(
    'assetpak',
    'source/assetpak.d',
    common_src,
    include_directories: inc
)