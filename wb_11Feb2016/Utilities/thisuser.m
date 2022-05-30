function user=thisuser()
%report the system username as a string
%130923

user=char(java.lang.System.getProperty('user.name'));