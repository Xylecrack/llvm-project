#include <stdio.h>

int main(){
    int n = 5;
    int res = 1;
    for(int i =1;i<=n;i++){
        res*=i;
    }
    printf("%d\n",res);
    return 0;
}