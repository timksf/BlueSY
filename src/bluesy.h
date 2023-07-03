#ifndef BLUESY_H
#define BLUESY_H

#include <cstdint>
#include <functional>
#include <vector>
#include <iostream>

#include "map.h"

namespace bluesy{
    using ptr_type = void*;

    template <typename T>
    struct TypeToString{
        //basic fallback implementation
        static const char* get(){
            return typeid(T).name();
        }
    };

    template<typename ...Args>
    void log(Args && ...args) {
        std::cout << "[bluesy] ";
        (std::cout << ... << args);
    }

    template<class CastTo>
    std::function<void (std::vector<ptr_type>&)> get_instance_deleter(){
        return 
        [] (std::vector<ptr_type>& instances) {
            log("Deleting all created instances of: ", TypeToString<CastTo>::get(), "\n");
            log("Total instances: ", instances.size(), "\n");
            for(ptr_type ptr : instances){
                delete ((CastTo*) ptr);
            }
        };
    }

}

#define REMOVE_FIRST(f, ...) __VA_ARGS__

#define ENABLE_TYPENAME(A)                      \
    template<>                                  \
    struct bluesy::TypeToString<A> {            \
        static const char* get() { return #A; } \
    };

#define AS_ARG_0
#define AS_ARG_1(type, name) type name
#define AS_ARG_PAIR_0() AS_ARG_0
#define AS_ARG_PAIR_1(pair) AS_ARG_1 pair
#define AS_ARG_PAIR_X(x,A,F,...) F

#define AS_ARG_PAIR(...) AS_ARG_PAIR_X(__VA_OPT__(,)__VA_ARGS__,    \
                                        AS_ARG_PAIR_1(__VA_ARGS__), \
                                        AS_ARG_PAIR_0(__VA_ARGS__))

#define NAME_ONLY_0
#define NAME_ONLY_1(type, name) name
#define NAME_ONLY_PAIR_0() NAME_ONLY_0
#define NAME_ONLY_PAIR_1(pair) NAME_ONLY_1 pair
#define NAME_ONLY_PAIR_X(x,A,F,...) F

#define NAME_ONLY_PAIR(...) NAME_ONLY_PAIR_X(__VA_OPT__(,)__VA_ARGS__,          \
                                                NAME_ONLY_PAIR_1(__VA_ARGS__),  \
                                                NAME_ONLY_PAIR_0(__VA_ARGS__))

/*
    In BSV there is no easy way to execute functions when a program/simulation ends. 
    The created C++ objects are on the heap though and thus have to be deleted to avoid
    memory leaks. 
    This macro creates a vector that keeps track of all created instances. A function
    for deleting all instances is created, this function is later registered with atexit.
*/
#define BSV_ENABLE_PSEUDO_GC(C) \
    static std::vector<bluesy::ptr_type> instances_##C;                                 \
    static bool registered_##C = false;                                                 \
    static auto instance_deleter_##C = bluesy::get_instance_deleter<C>();               \
    ENABLE_TYPENAME(C);

/*
    Wraps the constructor of a C++ class into a C function that can be called from BSV.
    The name of the generated C function is
        create_<class name>(args...)
    Needs the pseudo-gc generated static variables to register the clean-up function with 
    atexit, execute BSV_ENABLE_PSEUDO_GC(<class name>) before.
*/
#define BSV_WRAP_CONSTRUCTOR(C, ...)                                                                \
    extern "C" {                                                                                    \
        bluesy::ptr_type create_##C(MAP_LIST(AS_ARG_PAIR, __VA_ARGS__)){                            \
                                                                                                    \
            if(!registered_##C){                                                                    \
                void (*f) () = [] { instance_deleter_##C(instances_##C); };                         \
                const int code = atexit(f);                                                         \
                if(code != 0){                                                                      \
                    bluesy::log("Could not register exit handler for", #C, "\n");                   \
                    exit(EXIT_FAILURE);                                                             \
                }else{                                                                              \
                    registered_##C = true;                                                          \
                    bluesy::log("Successfully registered exit handler for ", #C, "\n");             \
                }                                                                                   \
            }                                                                                       \
            bluesy::ptr_type _ptr = (bluesy::ptr_type) new C(MAP_LIST(NAME_ONLY_PAIR, __VA_ARGS__));\
            instances_##C.push_back(_ptr);                                                          \
            return _ptr;                                                                            \
        }                                                                                           \
    }                                                                               

/*
    Wraps an instance method of a C++ class into a C function, which takes an additional argument.
    The additional argument is a pointer to an object of the C++ class.
    The name of the C function is "<method_name>_<class name>".
    All parameters have to be supplied as a pair of (<type>, <name>).
    Example:
        Consider a class RandomAccessMemory with method "write_word" which has the following signature:
            bool write_word(uint32_t addr, uint32_t word)
        You then use BSV_WRAP_INSTANCE_METHOD(RandomAccessMemory, write_word, bool, (uint32_t, addr), (uint32_t, word))
        This will define the following C function:
            bool write_word_RandomAccessMemory(bluesy::ptr_type p, uint32_t addr, uint32_t word)
        This function can then easily be imported in BSV as e.g.:
            import "BDPI" function ActionValue#(UInt#(32)) write_word_RandomAccessMemory(UInt#(64) ptr, UInt#(32) addr, UInt#(32) word)

*/
#define BSV_WRAP_INSTANCE_METHOD(C, m, ret, ...) BSV_WRAP_INSTANCE_METHOD__INT(C,m,ret,(bluesy::ptr_type, p) __VA_OPT__(,) __VA_ARGS__)

#define BSV_WRAP_INSTANCE_METHOD__INT(C, m, ret, ...)                                   \
    extern "C" {                                                                        \
        ret m##_##C(MAP_LIST(AS_ARG_PAIR, __VA_ARGS__)){                                \
            return ((C*) p)->m(MAP_LIST(NAME_ONLY_PAIR, REMOVE_FIRST(__VA_ARGS__)));    \
        }                                                                               \
    }

/*
    Same thing for class methods, see above.
*/
#define BSV_WRAP_CLASS_METHOD(C, m, ret, ...)                                           \
    extern "C" {                                                                        \
        ret m##_##C(MAP_LIST(AS_ARG_PAIR, __VA_ARGS__)){                                \
            return C::m(MAP_LIST(NAME_ONLY_PAIR, __VA_ARGS__));                         \
        }                                                                               \
    }

/*
    Use this in the C++ header file, if you want to use the create_<class> function in
    your C++ code somewhere.
*/
#define BSV_CONSTRUCTOR_HEADER_DEF(C, ...)                                              \
    extern "C" {                                                                        \
        bluesy::ptr_type create_##C(MAP_LIST(AS_ARG_PAIR, __VA_ARGS__));                \
    }




#endif //BLUESY_H