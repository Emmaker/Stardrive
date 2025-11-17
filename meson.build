project('dbound', 'd', version: '0.1', default_options: ['warning_level=3'])

inc = include_directories('source')
# where common_src is defined
subdir('source')

common = static_library('common', common_src, include_directories: inc)
common_dep = declare_dependency(link_with: common)

executable(
    'assetpak',
    'source/assetpak.d',
    include_directories: inc,
    dependencies: [common_dep],
)