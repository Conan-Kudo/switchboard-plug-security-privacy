find_package (PkgConfig)

# Add all your dependencies to the list below
pkg_check_modules (DEPS REQUIRED gthread-2.0 gtk+-3.0 switchboard-2.0 granite polkit-gobject-1 zeitgeist-2.0)

add_definitions (${DEPS_CFLAGS})
link_directories (${DEPS_LIBRARY_DIRS})

find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.34.1" MINIMUM)

include (ValaPrecompile)
# Add all your vala files and requires packages to the List below to include them in the build
vala_precompile (VALA_C ${CMAKE_PROJECT_NAME}
    BlackList.vala
    Plug.vala
    UFWHelpers.vala
    ZGUtilities.vala

    Views/AbstractServicePanel.vala
    Views/FirewallPanel.vala
    Views/LockPanel.vala
    Views/TrackPanel.vala
    Views/LocationPanel.vala

    Widgets/AppChooser.vala
    Widgets/AppRow.vala
    Widgets/ClearUsagePopover.vala
    Widgets/ExcludeTreeView.vala
    Widgets/IncludeTreeView.vala
    Widgets/ServiceItem.vala
    Widgets/ServiceList.vala

    ${CMAKE_CURRENT_BINARY_DIR}/config.vala
PACKAGES
    gtk+-3.0
    switchboard-2.0
    granite
    polkit-gobject-1
    zeitgeist-2.0
    posix
)

add_library (${CMAKE_PROJECT_NAME} MODULE ${VALA_C})
target_link_libraries (${CMAKE_PROJECT_NAME} ${DEPS_LIBRARIES}) 

# Installation
install (TARGETS ${CMAKE_PROJECT_NAME} DESTINATION ${PKGDATADIR})
